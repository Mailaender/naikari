/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef NLUA_SHADER_H
#  define NLUA_SHADER_H


#include <lua.h>

#include "nlua.h"
#include "opengl.h"


#define SHADER_METATABLE      "shader" /**< Shader metatable identifier. */


typedef struct LuaShader_s {
   GLuint program;
} LuaShader_t;


/*
 * Library loading
 */
int nlua_loadShader( nlua_env env );

/*
 * Shader operations
 */
LuaShader_t* lua_toshader( lua_State *L, int ind );
LuaShader_t* luaL_checkshader( lua_State *L, int ind );
LuaShader_t* lua_pushshader( lua_State *L, LuaShader_t shader );
int lua_isshader( lua_State *L, int ind );


#endif /* NLUA_SHADER_H */


