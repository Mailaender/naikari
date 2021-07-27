/*
 * See Licensing and Copyright notice in naev.h
 */


/** @cond */
#include <float.h>
#include "SDL.h"
/** @endcond */

#include "map_overlay.h"

#include "array.h"
#include "conf.h"
#include "font.h"
#include "gui.h"
#include "input.h"
#include "log.h"
#include "naev.h"
#include "nstring.h"
#include "opengl.h"
#include "pilot.h"
#include "player.h"
#include "space.h"

#if HAVE_SUITESPARSE_CHOLMOD_H
#include <suitesparse/cholmod.h>
#else /* HAVE_SUITESPARSE_CHOLMOD_H */
#include <cholmod.h>
#endif /* HAVE_SUITESPARSE_CHOLMOD_H */

/**
 * Structure for map overlay size.
 */
typedef struct MapOverlayRadiusConstraint_ {
   int i; /**< this radius... */
   int j; /**< plus this radius... */
   double dist; /**< ... is at most this big. */
} MapOverlayRadiusConstraint;


/**
 * @brief An overlay map marker.
 */
typedef struct ovr_marker_s {
   unsigned int id; /**< ID of the marker. */
   char *text; /**< Marker display text. */
   int type; /**< Marker type. */
   union {
      struct {
         double x; /**< X center of point marker. */
         double y; /**< Y center of point marker. */
      } pt; /**< Point marker. */
   } u; /**< Type data. */
} ovr_marker_t;
static unsigned int mrk_idgen = 0; /**< ID generator for markers. */
static ovr_marker_t *ovr_markers = NULL; /**< Overlay markers. */


static Uint32 ovr_opened = 0; /**< Time last opened. */
static int ovr_open = 0; /**< Is the overlay open? */
static double ovr_res = 10.; /**< Resolution. */

static cholmod_common C; /**< Parameter settings, statistics, and workspace used internally by CHOLMOD (label position optimizer). */

/*
 * Prototypes
 */
static int force_collision( float *ox, float *oy,
      float x, float y, float w, float h,
      float mx, float my, float mw, float mh );
static void ovr_optimizeLayout( int items, const Vector2d** pos,
      MapOverlayPos** mo, float res );
static int ovr_refresh_uzawa_overlap( cholmod_dense *forces_x, cholmod_dense *forces_y,
      float res, float x, float y, float w, float h, const Vector2d** pos,
      MapOverlayPos** mo, MapOverlayPosOpt* moo, int items, int self, float pixbuf );
/* Markers. */
static void ovr_mrkRenderAll( double res );
static void ovr_mrkCleanup(  ovr_marker_t *mrk );
static ovr_marker_t *ovr_mrkNew (void);


/**
 * @brief Check to see if the map overlay is open.
 */
int ovr_isOpen (void)
{
   return !!ovr_open;
}

/**
 * @brief Handles input to the map overlay.
 */
int ovr_input( SDL_Event *event )
{
   int mx, my;
   double x, y;

   /* We only want mouse events. */
   if (event->type != SDL_MOUSEBUTTONDOWN)
      return 0;

   /* Player must not be NULL. */
   if (player_isFlag(PLAYER_DESTROYED) || (player.p == NULL))
      return 0;

   /* Player must not be dead. */
   if (pilot_isFlag(player.p, PILOT_DEAD))
      return 0;

   /* Mouse targeting only uses left and right buttons. */
   if (event->button.button != SDL_BUTTON_LEFT &&
            event->button.button != SDL_BUTTON_RIGHT)
      return 0;

   /* Translate from window to screen. */
   mx = event->button.x;
   my = event->button.y;
   gl_windowToScreenPos( &mx, &my, mx, my );

   /* Translate to space coords. */
   x = ((double)mx - (double)map_overlay_center_x()) * ovr_res;
   y = ((double)my - (double)map_overlay_center_y()) * ovr_res;

   return input_clickPos( event, x, y, 1., 10. * ovr_res, 15. * ovr_res );
}


/**
 * @brief Refreshes the map overlay recalculating the dimensions it should have.
 *
 * This should be called if the planets or the likes change at any given time.
 */
void ovr_refresh (void)
{
   double max_x, max_y;
   int i, items, jumpitems;
   Planet *pnt;
   JumpPoint *jp;
   const Vector2d **pos;
   MapOverlayPos **mo;
   char buf[STRMAX_SHORT];

   /* Must be open. */
   if (!ovr_isOpen())
      return;

   /* Calculate max size. */
   items = 0;
   pos = calloc(array_size(cur_system->jumps) + array_size(cur_system->planets), sizeof(Vector2d*));
   mo  = calloc(array_size(cur_system->jumps) + array_size(cur_system->planets), sizeof(MapOverlayPos*));
   max_x = 0.;
   max_y = 0.;
   for (i=0; i<array_size(cur_system->jumps); i++) {
      jp = &cur_system->jumps[i];
      max_x = MAX( max_x, ABS(jp->pos.x) );
      max_y = MAX( max_y, ABS(jp->pos.y) );
      if (!jp_isUsable(jp) || !jp_isKnown(jp))
         continue;
      /* Initialize the map overlay stuff. */
      snprintf( buf, sizeof(buf), "%s%s", jump_getSymbol(jp), sys_isKnown(jp->target) ? _(jp->target->name) : _("Unknown") );
      pos[items] = &jp->pos;
      mo[items]  = &jp->mo;
      mo[items]->radius = jumppoint_gfx->sw;
      mo[items]->text_width = gl_printWidthRaw(&gl_smallFont, buf);
      items++;
   }
   jumpitems = items;
   for (i=0; i<array_size(cur_system->planets); i++) {
      pnt = cur_system->planets[i];
      max_x = MAX( max_x, ABS(pnt->pos.x) );
      max_y = MAX( max_y, ABS(pnt->pos.y) );
      if ((pnt->real != ASSET_REAL) || !planet_isKnown(pnt))
         continue;
      /* Initialize the map overlay stuff. */
      snprintf( buf, sizeof(buf), "%s%s", planet_getSymbol(pnt), _(pnt->name) );
      pos[items] = &pnt->pos;
      mo[items]  = &pnt->mo;
      mo[items]->radius = pnt->radius;
      mo[items]->text_width = gl_printWidthRaw( &gl_smallFont, buf );
      items++;
   }

   /* We need to calculate the radius of the rendering from the maximum radius of the system. */
   ovr_res = 2. * 1.2 * MAX( max_x / map_overlay_width(), max_y / map_overlay_height() );
   for (i=0; i<items; i++)
      mo[i]->radius = MAX( mo[i]->radius / ovr_res, i<jumpitems ? 10. : 15. );

   /* Nothing in the system so we just set a default value. */
   if (items == 0)
      ovr_res = 50.;

   /* Compute text overlap and try to minimize it. */
   ovr_optimizeLayout( items, pos, mo, ovr_res );

   /* Free the moos. */
   free( mo );
   free( pos );
}


/**
 * @brief Makes a best effort to fit the given assets' overlay indicators and labels fit without collisions.
 */
static void ovr_optimizeLayout( int items, const Vector2d** pos, MapOverlayPos** mo, float res )
{
   int i, j, iter;
   float cx, cy, r;
   cholmod_dense *forces_x, *forces_y, *sum_x, *sum_y;
   float sx, sy;

   /* Parameters for the map overlay optimization. */
   const int max_iters = 10; /**< Maximum amount of iterations to do. */
   const float pixbuf = 5.; /**< Pixels to buffer around for text (not used for optimizing radius). */

   if (items <= 0)
      return;

   /* Fix radii which fit together. */
   MapOverlayRadiusConstraint cur, *fits = array_create(MapOverlayRadiusConstraint);
   uint8_t *must_shrink = malloc( items );
   for (cur.i=0; cur.i<items; cur.i++)
      for (cur.j=cur.i+1; cur.j<items; cur.j++) {
         cur.dist = hypot( pos[cur.i]->x - pos[cur.j]->x, pos[cur.i]->y - pos[cur.j]->y ) / res;
         cur.dist *= 2; /* Oh, for the love of God, did someone make "radius" a diameter again? */
         if (cur.dist < mo[cur.i]->radius + mo[cur.j]->radius)
            array_push_back( &fits, cur );
      }
   while (array_size( fits ) > 0) {
      float shrink_factor = 0;
      memset( must_shrink, 0, items );
      for (i = 0; i < array_size( fits ); i++)
      {
         r = fits[i].dist / (mo[fits[i].i]->radius + mo[fits[i].j]->radius);
         if (r >= 1)
            array_erase( &fits, &fits[i], &fits[i+1] );
         else {
            shrink_factor = MAX( shrink_factor, r - FLT_EPSILON );
            must_shrink[fits[i].i] = must_shrink[fits[i].j] = 1;
         }
      }
      for (i=0; i<items; i++)
         if (must_shrink[i])
            mo[i]->radius *= shrink_factor;
   }
   free( must_shrink );
   array_free( fits );

   /* Initialize all items. */
   for (i=0; i<items; i++) {
      /* Test to see what side is best to put the text on.
       * We actually compute the text overlap also so hopefully it will alternate
       * sides when stuff is clustered together. */
      cx = pos[i]->x / res;
      cy = pos[i]->y / res;
      /* Initialize mo. */
      mo[i]->text_offx = 0;
      mo[i]->text_offy = 0;
   }

   /* Uzawa optimization algorithm.
    * We minimize the (weighted) L2 norm of vector of offsets and radius changes
    * Under the constraint of no interpenetration
    * As the algorithm is Uzawa, this constraint won't necessary be attained.
    * This is similar to a contact problem is mechanics. */

   /* Initialize the cholmod and the matrix that stores the dual variables (forces applied between objects).
    * cholmod matrix is column-major, this means it is interesting to store in each column the forces
    * recieved by a given object. Then these forces are summed to obtain the total force on the object.
    * Odd lines are forces from objects and Even lines from other texts. */

   cholmod_start( &C );
   forces_x = cholmod_zeros( 2*items, items, CHOLMOD_REAL, &C );
   forces_y = cholmod_zeros( 2*items, items, CHOLMOD_REAL, &C );
/*   sum_x = cholmod_zeros( items, 1, CHOLMOD_REAL, &C );*/
/*   sum_y = cholmod_zeros( items, 1, CHOLMOD_REAL, &C );*/

   /* Main Uzawa Loop. */
   for (iter=0; iter<max_iters; iter++) {
      // int changed = 0;
      for (i=0; i<items; i++) {
         cx = pos[i]->x / res;
         cy = pos[i]->y / res;
         /* Compute the forces. */
         //DEBUG("mo[i]->text_offx = %f",mo[i]->text_offx);
         if (ovr_refresh_uzawa_overlap( forces_x, forces_y, res, cx+mo[i]->text_offx-pixbuf, cy+mo[i]->text_offy-pixbuf, mo[i]->text_width+2*pixbuf, gl_smallFont.h+2*pixbuf, pos, mo, items, i, pixbuf )) {
            //changed = 1; /* TODO: get rid of this and find a proper stopping criterion. */
         }

         /* Do the sum. */
         sx = 0.;
         sy = 0.;
         for (j=0; j<items; j++) {
            sx += ((double*)forces_x->x)[2*items*i+2*j+1] + ((double*)forces_x->x)[2*items*i+2*j];
            sy += ((double*)forces_y->x)[2*items*i+2*j+1] + ((double*)forces_y->x)[2*items*i+2*j];
/*            DEBUG("fx = %f",((double*)forces_x->x)[2*items*i+2*j+1]);*/
/*            DEBUG("fx = %f",((double*)forces_x->x)[2*items*i+2*j]);*/
/*            DEBUG("fy = %f",((double*)forces_y->x)[2*items*i+2*j+1]);*/
/*            DEBUG("fy = %f",((double*)forces_y->x)[2*items*i+2*j]);*/
         }

         //DEBUG("sy = %f",sy);

         /* Update positions (in buffer). Diagonal stiffness.
          * (moving along y is more likely to be the right solution)*/
         mo[i]->text_offx = .1 * sx; //.1 * sx; /* TODO: decide. */
         mo[i]->text_offy = .3 * sy; // .3
      }
      //DEBUG("%f",((double*)forces_x->x)[items*0+1]);
      //DEBUG("%f",sx);
      //DEBUG("%d",items);

      /* Converged (or unnecessary). */
/*      if (!changed)*/
/*         break;*/
   }

   /* Free the forces matrix. */
   cholmod_free_dense( &forces_x, &C );
   cholmod_free_dense( &forces_y, &C );
/*   cholmod_free_dense( &sum_x, &C );*/
/*   cholmod_free_dense( &sum_y, &C );*/
   cholmod_finish( &C );
}


/**
 * @brief Compute a collision between two rectangles and direction to deduce the force.
 */
static int force_collision( float *ox, float *oy,
      float x, float y, float w, float h,
      float mx, float my, float mw, float mh )
{

   /* No contact because of y offset (5 pix tolerance). */
   if (((y+h) < my+5) || (y+5 > (my+mh)))
      *ox = 0;
   else {
      /* Case A is left of B. */
      if (x < mx) {
         *ox += mx-(x+w);
         *ox = MIN(0., *ox);
      }
      /* Case A is to the right of B. */
      else {
         *ox += (mx+mw)-x;
         *ox = MAX(0., *ox);
      }
   }

   /* No contact because of x offset (5 pix tolerance). */
   if (((x+w) < mx+5) || (x+5 > (mx+mw)))
      *oy = 0;
   else {
      /* Case A is below B. */
      if (y < my) {
         *oy += my-(y+h);
         *oy = MIN(0., *oy);
      }
      /* Case A is above B. */
      else {
         *oy += (my+mh)-y;
         *oy = MAX(0., *oy);
      }
   }

   /* No collision. TODO: get rid of this one. */
   if (((x+w) < mx+5) || (x+5 > (mx+mw)))
      return 0;
   if (((y+h) < my+5) || (y+5 > (my+mh)))
      return 0;

   return 1;
}


/**
 * @brief Compute how an element overlaps with text and force to move away.
 */
static int ovr_refresh_uzawa_overlap( cholmod_dense *forces_x, cholmod_dense *forces_y,
      float res, float x, float y, float w, float h, const Vector2d** pos,
      MapOverlayPos** mo, int items, int self, float pixbuf )
{
   int i, collided;
   float mx, my, mw, mh, fx, fy;
   const float pb2 = pixbuf*2.;

   collided = 0;

   for (i=0; i<items; i++) {
      fx = ((double*)forces_x->x)[2*items*self+2*i+1];
      fy = ((double*)forces_y->x)[2*items*self+2*i+1];

      /* Collisions with planet circles and jp triangles (odd indices). */
      mw = mo[i]->radius + pb2;
      mh = mw;
      mx = pos[i]->x/res - mw/2.;
      my = pos[i]->y/res - mh/2.;
      //DEBUG("x=%f, mx=%f, w=%f, mw=%f", x,mx,w,mw);
      collided |= force_collision( &fx, &fy, x, y, w, h, mx, my, mw, mh );

      ((double*)forces_x->x)[2*items*self+2*i+1] = fx;
      ((double*)forces_y->x)[2*items*self+2*i+1] = fy;

      if (i == self)
         continue;

      fx = ((double*)forces_x->x)[2*items*self+2*i];
      fy = ((double*)forces_y->x)[2*items*self+2*i];

      /* Collisions with other texts (even indices) */
      mw = mo[i]->text_width + pb2;
      mh = gl_smallFont.h + pb2;
      mx = pos[i]->x/res + mo[i]->text_offx - pixbuf;
      my = pos[i]->y/res + mo[i]->text_offy - pixbuf;
      collided |= force_collision( &fx, &fy, x, y, w, h, mx, my, mw, mh );

      ((double*)forces_x->x)[2*items*self+2*i] = fx;
      ((double*)forces_y->x)[2*items*self+2*i] = fy;

   }

   return collided;
}


/**
 * @brief Properly opens or closes the overlay map.
 *
 *    @param open Whether or not to open it.
 */
void ovr_setOpen( int open )
{
   if (open && !ovr_open) {
      ovr_open = 1;
      input_mouseShow();
   }
   else if (ovr_open) {
      ovr_open = 0;
      input_mouseHide();
   }
}


/**
 * @brief Handles a keypress event.
 *
 *    @param type Type of event.
 */
void ovr_key( int type )
{
   if (type > 0) {
      if (ovr_open)
         ovr_setOpen(0);
      else {
         ovr_setOpen(1);

         /* Refresh overlay size. */
         ovr_refresh();
         ovr_opened = SDL_GetTicks();
      }
   }
   else if (type < 0) {
      if (SDL_GetTicks() - ovr_opened > 300)
         ovr_setOpen(0);
   }
}


/**
 * @brief Renders the overlay map.
 *
 *    @param dt Current delta tick.
 */
void ovr_render( double dt )
{
   (void) dt;
   int i, j;
   Pilot *const*pstk;
   AsteroidAnchor *ast;
   double w, h, res;
   double x,y;

   /* Must be open. */
   if (!ovr_open)
      return;

   /* Player must be alive. */
   if (player_isFlag( PLAYER_DESTROYED ) || (player.p == NULL))
      return;

   /* Default values. */
   w     = map_overlay_width();
   h     = map_overlay_height();
   res   = ovr_res;

   /* First render the background overlay. */
   glColour c = { .r=0., .g=0., .b=0., .a= conf.map_overlay_opacity };
   gl_renderRect( (double)gui_getMapOverlayBoundLeft(), (double)gui_getMapOverlayBoundRight(), w, h, &c );

   /* Render planets. */
   for (i=0; i<array_size(cur_system->planets); i++)
      if ((cur_system->planets[ i ]->real == ASSET_REAL) && (i != player.p->nav_planet))
         gui_renderPlanet( i, RADAR_RECT, w, h, res, 1 );
   if (player.p->nav_planet > -1)
      gui_renderPlanet( player.p->nav_planet, RADAR_RECT, w, h, res, 1 );

   /* Render jump points. */
   for (i=0; i<array_size(cur_system->jumps); i++)
      if ((i != player.p->nav_hyperspace) && !jp_isFlag(&cur_system->jumps[i], JP_EXITONLY))
         gui_renderJumpPoint( i, RADAR_RECT, w, h, res, 1 );
   if (player.p->nav_hyperspace > -1)
      gui_renderJumpPoint( player.p->nav_hyperspace, RADAR_RECT, w, h, res, 1 );

   /* Render pilots. */
   pstk  = pilot_getAll();
   j     = 0;
   for (i=0; i<array_size(pstk); i++) {
      if (pstk[i]->id == PLAYER_ID) /* Skip player. */
         continue;
      if (pstk[i]->id == player.p->target)
         j = i;
      else
         gui_renderPilot( pstk[i], RADAR_RECT, w, h, res, 1 );
   }
   /* Render the targeted pilot */
   if (j!=0)
      gui_renderPilot( pstk[j], RADAR_RECT, w, h, res, 1 );

   /* Check if player has goto target. */
   if (player_isFlag(PLAYER_AUTONAV) && (player.autonav == AUTONAV_POS_APPROACH)) {
      x = player.autonav_pos.x / res + map_overlay_center_x();
      y = player.autonav_pos.y / res + map_overlay_center_y();
      gl_renderCross( x, y, 5., &cRadar_hilight );
      gl_printMarkerRaw( &gl_smallFont, x+10., y-gl_smallFont.h/2., &cRadar_hilight, _("TARGET") );
   }

   /* render the asteroids */
   for (i=0; i<array_size(cur_system->asteroids); i++) {
      ast = &cur_system->asteroids[i];
      for (j=0; j<ast->nb; j++)
         gui_renderAsteroid( &ast->asteroids[j], w, h, res, 1 );
   }

   /* Render the player. */
   gui_renderPlayer( res, 1 );

   /* Render markers. */
   ovr_mrkRenderAll( res );
}


/**
 * @brief Renders all the markers.
 *
 *    @param res Resolution to render at.
 */
static void ovr_mrkRenderAll( double res )
{
   int i;
   ovr_marker_t *mrk;
   double x, y;

   for (i=0; i<array_size(ovr_markers); i++) {
      mrk = &ovr_markers[i];

      x = mrk->u.pt.x / res + map_overlay_center_x();
      y = mrk->u.pt.y / res + map_overlay_center_y();
      gl_renderCross( x, y, 5., &cRadar_hilight );

      if (mrk->text != NULL)
         gl_printMarkerRaw( &gl_smallFont, x+10., y-gl_smallFont.h/2., &cRadar_hilight, mrk->text );
   }
}


/**
 * @brief Frees up and clears all marker related stuff.
 */
void ovr_mrkFree (void)
{
   /* Clear markers. */
   ovr_mrkClear();

   /* Free array. */
   array_free( ovr_markers );
   ovr_markers = NULL;
}


/**
 * @brief Clears the current markers.
 */
void ovr_mrkClear (void)
{
   int i;
   for (i=0; i<array_size(ovr_markers); i++)
      ovr_mrkCleanup( &ovr_markers[i] );
   array_erase( &ovr_markers, array_begin(ovr_markers), array_end(ovr_markers) );
}


/**
 * @brief Clears up after an individual marker.
 *
 *    @param mrk Marker to clean up after.
 */
static void ovr_mrkCleanup( ovr_marker_t *mrk )
{
   free( mrk->text );
   mrk->text = NULL;
}


/**
 * @brief Creates a new marker.
 *
 *    @return The newly created marker.
 */
static ovr_marker_t *ovr_mrkNew (void)
{
   ovr_marker_t *mrk;

   if (ovr_markers == NULL)
      ovr_markers = array_create(  ovr_marker_t );

   mrk = &array_grow( &ovr_markers );
   memset( mrk, 0, sizeof( ovr_marker_t ) );
   mrk->id = ++mrk_idgen;
   return mrk;
}


/**
 * @brief Creates a new point marker.
 *
 *    @param text Text to display with the marker.
 *    @param x X position of the marker.
 *    @param y Y position of the marker.
 *    @return The id of the newly created marker.
 */
unsigned int ovr_mrkAddPoint( const char *text, double x, double y )
{
   ovr_marker_t *mrk;

   mrk = ovr_mrkNew();
   mrk->type = 0;
   if (text != NULL)
      mrk->text = strdup( text );
   mrk->u.pt.x = x;
   mrk->u.pt.y = y;

   return mrk->id;
}


/**
 * @brief Removes a marker by id.
 *
 *    @param id ID of the marker to remove.
 */
void ovr_mrkRm( unsigned int id )
{
   int i;
   for (i=0; i<array_size(ovr_markers); i++) {
      if (id!=ovr_markers[i].id)
         continue;
      ovr_mrkCleanup( &ovr_markers[i] );
      array_erase( &ovr_markers, &ovr_markers[i], &ovr_markers[i+1] );
      break;
   }
}


