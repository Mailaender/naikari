/**
 * See Licensing and Copyright notice in naev.h
 */

#ifndef OBJECT_H
#  define OBJECT_H

/** @cond */
#include "SDL.h"
/** @endcond */

#include "opengl_vbo.h"
#include "physics.h"

struct gl_vbo;

typedef struct Material_ {
   char *name;
   GLfloat Ka[3], Kd[3], Ks[3];
   GLfloat Ns, Ni, d, bm;
   glTexture *map_Kd, *map_Bump;
} Material;

typedef struct Mesh_ {
   char *name;
   gl_vbo *vbo;
   int num_corners;
   int material;
} Mesh;

typedef struct Object_ {
   Mesh *meshes;
   Material *materials;
   GLfloat radius;
} Object;


Object *object_loadFromFile( const char *filename);
void object_renderSolidPart( Object *object, const Solid *solid, const char *part_name, GLfloat alpha, GLdouble scale );
void object_free( Object *object );



#endif
