local lanes = {}

--[[
-- Gets the index to the nearest vertex to a position.
--]]
local function nearestVertex( vertices, pos )
   local n = nil
   local nd = math.huge
   for k,v in ipairs(vertices) do
      local d = v:dist2(pos)
      if d < nd then
         nd = d
         n = k
      end
   end
   return n
end

--[[
-- Converts the safelane structure to a nice list of vertices and edges
--]]
local function safelanesToGraph( lanes )
   local eps = 1e-5
   local vertices = {}
   local edges = {}
   for k,v in ipairs(lanes) do
      local v1, v2
      for i,p in ipairs(vertices) do
         if p:dist2(v[1]) < eps then
            v1 = i
         end
         if p:dist2(v[2]) < eps then
            v2 = i
         end
      end
      if not v1 then
         local n = #vertices+1
         vertices[n] = v[1]
         v1 = n
      end
      if not v2 then
         local n = #vertices+1
         vertices[n] = v[2]
         v2 = n
      end
      table.insert( edges, {v1, v2} )
   end
   return vertices, edges
end

--[[
-- You run of the mill djikstra algorithm
--]]
local function djikstra( vertices, edges, source, target )
   local Q = {}
   for k,v in ipairs(vertices) do
      local q = {
         v=k, -- Index of vertex
         d=math.huge, -- Gigantic initial distance
         p=nil, -- No previous node
      }
      table.insert( Q, q )
   end

   -- Build edges of qs
   local E = {}
   for k,e in ipairs(edges) do
      table.insert( E, {Q[e[1]], Q[e[2]]} )
   end

   -- Initialize source
   Q[source].d = 0

   -- Start iterating
   while #Q > 0 do
      -- Vertex with minimum distance
      table.sort( Q, function(a, b) return a.d < b.d end )
      u = Q[1]
      table.remove( Q, 1 )

      -- Search done
      if u.v == target then
         -- Create the path by iterating backwards
         local S = {}
         while u do
            table.insert( S, vertices[u.v] )
            u = u.p
         end
         return S
      end

      -- Get neighbours
      local N = {}
      for k,e in ipairs(E) do
         if e[1] == u then
            table.insert( N, e[2] )
         elseif e[2] == u then
            table.insert( N, e[1] )
         end
      end

      -- Update distance
      for k,v in ipairs(N) do
         local alt = u.d + vertices[u.v]:dist( vertices[v.v] )
         if alt < v.d then
            v.d = alt
            v.p = u
         end
      end
   end

   -- No path found
   if target then
      return nil
   end
   -- Return the entire structure if no target
   return Q
end

--[[
-- Djikstra but considering everything is fully connected with different
-- penalty for travelling through non-safe areas.
--]]
local function djikstra_full( vertices, edges, source, target )
   local Q = {}
   local N = {}
   for k,v in ipairs(vertices) do
      local q = {
         v=k, -- Index of vertex
         d=math.huge, -- Gigantic initial distance
         p=nil, -- No previous node
      }
      table.insert( Q, q )
      table.insert( N, q )
   end

   -- Build penalty matrix
   local P = {}
   local n = #vertices
   for i=1,n do
      P[i] = {}
      for j=1,n do
         P[i][j] = 10 -- penalty
      end
   end
   for k,e in ipairs(edges) do
      P[e[1]][e[2]] = 1
      P[e[2]][e[1]] = 1
   end

   -- Initialize source
   Q[source].d = 0

   -- Start iterating
   while #Q > 0 do
      -- Vertex with minimum distance
      table.sort( Q, function(a, b) return a.d < b.d end )
      u = Q[1]
      table.remove( Q, 1 )

      -- Search done
      if u.v == target then
         -- Create the path by iterating backwards
         local S = {}
         while u do
            table.insert( S, vertices[u.v] )
            u = u.p
         end
         return S
      end

      -- Fully connected, so all are neighbours
      for k,v in ipairs(N) do
         local p = P[u.v][k]
         local alt = u.d + p*vertices[u.v]:dist( vertices[v.v] )
         if alt < v.d then
            v.d = alt
            v.p = u
         end
      end
   end

   -- No path found
   if target then
      return nil
   end
   -- Return the entire structure if no target
   return Q
end


--[[
-- Gets the closest point to a point p on a line segment a-b.
--]]
local function closestPointLine( a, b, p )
   local ap = p-a
   local ab = b-a
   local t  = ap:dot( ab ) / ab:dist2()
   t = math.max( 0, math.min( 1, t ) ) -- Clamp so it is on line segment
   return a + ab * t
end


local function getCache ()
   -- We try to cache the lane graph per system
   -- TODO handle hostile lanes and such
   local nc = naev.cache()
   if not nc.lanes then nc.lanes = {} end
   local ncl = nc.lanes
   local sc = system.cur()
   if ncl.system ~= sc then
      ncl.lanes = safelanes.get()
      ncl.v, ncl.e = safelanesToGraph( ncl.lanes )
      ncl.system = sc
   end
   return ncl
end


--[[
-- Gets distance and nearest point to safe lanes from a position
--]]
function lanes.getDistance( pos )
   local d, p = lanes.getDistance2( pos )
   return math.sqrt(d), p
end


--[[
-- Gets squared distance and nearest point to safe lanes from a position
--]]
function lanes.getDistance2( pos )
   local ncl = getCache()
   local d = math.huge
   local p = pos
   for k,v in ipairs(ncl.lanes) do
      local pp = closestPointLine( v[1], v[2], pos )
      local dp = pos:dist2( pp )
      if dp < d then
         d = dp
         p = pp
      end
   end
   return d, p
end


--[[
-- Tries to get a point outside of the lanes, around a point at a radius rad.
-- We'll project the pos into radius if it is out of bounds.
--]]
function lanes.getNonPoint( pos, rad, margin, biasdir )
   local p, ews
   if not pos or not rad or not margin then
      p = ai.pilot()
      ews = p:stats().ew_stealth
   end
   pos = pos or p:pos()
   rad = rad or math.min( 2000, ews )
   margin = margin or ews
   local margin2 = margin*margin
   local srad2 = math.pow( system.cur():radius(), 2 )

   -- Make sure pos is in radius
   if pos:dist2() > srad2 then
      local m,a = pos:polar()
      pos = vec2.newP( system.cur():radius(), a )
   end

   -- Just some brute force sampling at different scales
   local n = 18
   local inc = 360 / n
   local sign = 1
   if rnd.rnd() < 0.5 then sign = -1 end
   for s in ipairs{1.0, 0.5, 1.5, 2.0, 3.0, 5.0} do
      local a = biasdir or rnd.rnd() * 360
      local r = rad * s
      for i=1,n do
         local pp = pos + vec2.newP( r, a )
         a = a + i * inc * sign
         sign = sign * -1
         if pp:dist2() < srad2 then
            local d = lanes.getDistance2( pp )
            if d > margin2 then
               return pp
            end
         end
      end
   end
   return nil
end


--[[
-- Gets a random point of interest
--]]
function lanes.getPointInterest( pos )
   pos = pos or ai.pilot():pos()
   local ncl = getCache()
   local lv, le = ncl.v, ncl.e

   -- Case nothing of interest we just return a random position like in the old days
   -- TODO do something smarter here
   if #lv == 0 then
      local r = rnd.rnd() * system.cur():radius()
      local a = rnd.rnd() * 360
      return vec2.newP( rnd.rnd() * system.cur():radius(), rnd.rnd() * 360 )
   end

   return lv[ rnd.rnd(1,#lv) ]
   -- TODO try to find elements in the connected component and not random
   --[[
   local sv = nearestVertex( lv, pos )
   local S = djikstra( lv, le, sv )
   for k,v in ipairs(S) do
   end
   --]]
end


--[[
-- Computes the route for the pilot to get to target.
--]]
function lanes.getRoute( target, pos )
   return { target }
end


return lanes
