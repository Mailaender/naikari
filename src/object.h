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
   GLfloat Ka[4], Kd[4], Ks[4];
   GLfloat Ns, Ni, d;
   glTexture *texture;
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
} Object;


Object *object_loadFromFile( const char *filename);
void object_renderSolidPart( Object *object, const Solid *solid, const char *part_name, GLfloat alpha, GLdouble scale );
void object_free( Object *object );



#endif
