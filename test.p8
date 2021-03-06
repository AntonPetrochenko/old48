pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--advanced micro platformer
--@matthughson

--if you make a game with this
--starter kit, please consider
--linking back to the bbs post
--for this cart, so that others
--can learn from it too!
--enjoy! 
--@matthughson
                
--log

cartdata( "minervasya" )

printh("\n\n-------\n-start-\n-------")

--config
--------------------------------

--sfx
snd=
{
	jump=0,
}

--music tracks
mus=
{

}
-- giga clutch!

_mget = mget

function mget(x,y)
	return _mget(x,y%32)
end

function cmset(x,y,t)
	mset(x,y%32,t)
end

_spr = spr

function spr(s,x,y,...)
	_spr(s,x,y,...)
	_spr(s,x,y-256,...)
end

-- /giga clutch

--math
--------------------------------

--point to box intersection.
function intersects_point_box(px,py,x,y,w,h)
	if flr(px)>=flr(x) and flr(px)<flr(x+w) and
				flr(py)>=flr(y) and flr(py)<flr(y+h) then
		return true
	else
		return false
	end
end

--box to box intersection
function intersects_box_box(
	x1,y1,
	w1,h1,
	x2,y2,
	w2,h2)

	local xd=x1-x2
	local xs=w1*0.5+w2*0.5
	if abs(xd)>=xs then return false end

	local yd=y1-y2
	local ys=h1*0.5+h2*0.5
	if abs(yd)>=ys then return false end
	
	return true
end

function fget_at(x,y,f)
	return fget(mget(flr(x/8),flr(y/8)),f)
end

--check if pushing into side tile and resolve.
--requires self.dx,self.x,self.y, and 
--assumes tile flag 0 == solid
--assumes sprite size of 8x8
function collide_side(self)

	local offset=self.w/3
	for i=-(self.w/3),(self.w/3),2 do
	--if self.dx>0 then
		if fget(mget((self.x+(offset))/8,(self.y+i)/8),0) then
			self.dx=0
			self.x=(flr(((self.x+(offset))/8))*8)-(offset)
			return true
		end
	--elseif self.dx<0 then
		if fget(mget((self.x-(offset))/8,(self.y+i)/8),0) then
			self.dx=0
			self.x=(flr((self.x-(offset))/8)*8)+8+(offset)
			return true
		end
--	end
	end
	--didn't hit a solid tile.
	return false
end

--check if pushing into floor tile and resolve.
--requires self.dx,self.x,self.y,self.grounded,self.airtime and 
--assumes tile flag 0 or 1 == solid
function collide_floor(self)
	--only check for ground when falling.
	if self.dy<0 then
		return false
	end
	local landed=false
	--check for collision at multiple points along the bottom
	--of the sprite: left, center, and right.
	for i=-(self.w/3),(self.w/3),2 do
		local tile=mget((self.x+i)/8,(self.y+(self.h/2))/8)
		if fget(tile,0) or (fget(tile,1) and self.dy>=0) then
			self.dy=0
			self.y=(flr((self.y+(self.h/2))/8)*8)-(self.h/2)
			self.grounded=true
			self.airtime=0
			landed=true
		end
	end
	return landed
end

--check if pushing into roof tile and resolve.
--requires self.dy,self.x,self.y, and 
--assumes tile flag 0 == solid
function collide_roof(self)
	--check for collision at multiple points along the top
	--of the sprite: left, center, and right.
	local landed = false
	for i=-(self.w/3),(self.w/3),2 do
		if fget(mget((self.x+i)/8,(self.y-(self.h/2))/8),0) then
			self.dy=0
			self.y=flr((self.y-(self.h/2))/8)*8+8+(self.h/2)
			self.jump_hold_time=0
			landed = true
		end
	end
	return landed
end

--make 2d vector
function m_vec(x,y)
	local v=
	{
		x=x,
		y=y,
		
  --get the length of the vector
		get_length=function(self)
			return sqrt(self.x^2+self.y^2)
		end,
		
  --get the normal of the vector
		get_norm=function(self)
			local l = self:get_length()
			return m_vec(self.x / l, self.y / l),l;
		end,
	}
	return v
end

--square root.
function sqr(a) return a*a end

--round to the nearest whole number.
function round(a) return flr(a+0.5) end

--vector length
function vec_length(x,y)
	return sqrt(sqr(x)+sqr(y))
end

--normalize vec
function vec_normalize(x,y)
	local l = vec_length(x,y)
	return x/l,y/l
end

function cvec_angle(ex,ey,sx,sy)
	
	local sx = sx or 0
	local sy = sy or 0
	ey%=256
	sy%=256
	return atan2(sx - ex, sy - ey)
end

function vec_angle(ex,ey,sx,sy)
	
	local sx = sx or 0
	local sy = sy or 0
	return atan2(sx - ex, sy - ey)
end


--utils
--------------------------------

function distance(x1,_y1,x2,_y2)
	x1 /= 10
	x2 /= 10
	local y1 = _y1%256
	local y2 = _y2%256
	y1 /= 10
	y2 /= 10
	return vec_length(x2-x1,y2-y1)*10
end

--print string with outline.
function printo(str,startx,
															 starty,col,
															 col_bg)
	print(str,startx+1,starty,col_bg)
	print(str,startx-1,starty,col_bg)
	print(str,startx,starty+1,col_bg)
	print(str,startx,starty-1,col_bg)
	print(str,startx+1,starty-1,col_bg)
	print(str,startx-1,starty-1,col_bg)
	print(str,startx-1,starty+1,col_bg)
	print(str,startx+1,starty+1,col_bg)
	print(str,startx,starty,col)
end

--print string centered with 
--outline.
function printc(
	str,x,y,
	col,col_bg,
	special_chars)

	local len=(#str*4)+(special_chars*3)
	local startx=x-(len/2)
	local starty=y-2
	printo(str,startx,starty,col,col_bg)
end

function rspr(sx,sy,x,y,a,w)
    local ca,sa=cos(a),sin(a)
    local srcx,srcy
    local ddx0,ddy0=ca,sa
    local mask=shl(0xfff8,(w-1))
    w*=4
    ca*=w-0.5
    sa*=w-0.5
    local dx0,dy0=sa-ca+w,-ca-sa+w
    w=2*w-1
    for ix=0,w do
        srcx,srcy=dx0,dy0
        for iy=0,w do
            if band(bor(srcx,srcy),mask)==0 then
                local c=sget(sx+srcx,sy+srcy)
                if (c>0) pset(x+ix,y+iy,c)
            end
            srcx-=ddy0
            srcy+=ddx0
        end
        dx0+=ddx0
        dy0+=ddy0
    end
end

function m_text_particle(text,x,y)
	p = {
		x=x,
		y=y,
		text=text,
		timer=0,
		update = function(self)
			self.timer+=1
			if self.timer > 30 then
				del(particles,self)
			end
			self.y-=1
		end,
		--[[
	function printc(
	str,x,y,
	col,col_bg,
	special_chars)
]]
		draw = function(self)
			printc(self.text or "nil",self.x,self.y,rnd(16),1,0)
		end
	}
	add(particles,p)
end

function m_line_particle(x,y,c,_v)
	local v
	if not _v then 
		v = rnd(5) 
	else 
		v = rnd(_v) 
	end
	local rdx,rdy = vec_normalize(rnd(2)-1,rnd(2)-1)
	p = {
		x=x,
		y=y,

		dx=rdx*v,
		dy=rdy*v,
		timer=0,
		update = function(self)
			self.dx*=0.6
			self.dy*=0.6
			self.x+=self.dx
			self.y+=self.dy
			if abs(self.dx) < 0.1 and abs(self.dy) < 0.1 then
				del(particles,self)
			end
		end,
		draw = function(self)
			line(
				self.x,
				self.y,
				self.x+self.dx,
				self.y+self.dy,
				c
			)
		end
	}
	add(particles,p)
end

--objects
--------------------------------

camera_y = 0
--make the player
function m_player(x,y)

	--todo: refactor with m_vec.
	local p=
	{

		health = 10,
		score = 0,
		x=x,
		y=y,

		dx=0,
		dy=0,

		w=8,
		h=8,

		cdx = 0,
		cdy = 3,
		charge = true,
		
		max_dx=1,--max x speed
		max_dy=2,--max y speed

		jump_speed=-1.75,--jump veloclity
		acc=0.05,--acceleration
		dcc=0.8,--decceleration
		air_dcc=1,--air decceleration
		grav=0.15,

		drilling_timer = 0,

		--helper for more complex
		--button press tracking.
		--todo: generalize button index.
		jump_button=
		{
			update=function(self)
				--start with assumption
				--that not a new press.
				self.is_pressed=false
				if btn(5) then
					if not self.is_down then
						self.is_pressed=true
					end
					self.is_down=true
					self.ticks_down+=1
				else
					self.is_down=false
					self.is_pressed=false
					self.ticks_down=0
				end
			end,
			--state
			is_pressed=false,--pressed this frame
			is_down=false,--currently down
			ticks_down=0,--how long down
		},
		drill_button=
		{
			update=function(self)
				--start with assumption
				--that not a new press.
				self.is_pressed=false
				if btn(4) then
					if not self.is_down then
						self.is_pressed=true
					end
					self.is_down=true
					self.ticks_down+=1
				else
					self.is_down=false
					self.is_pressed=false
					self.ticks_down=0
				end
			end,
			--state
			is_pressed=false,--pressed this frame
			is_down=false,--currently down
			ticks_down=0,--how long down
		},

		jump_hold_time=0,--how long jump is held
		min_jump_press=5,--min time jump can be held
		max_jump_press=15,--max time jump can be held

		jump_btn_released=true,--can we jump again?
		grounded=false,--on ground

		airtime=0,--time since grounded
		
		--animation definitions.
		--use with set_anim()
		anims=
		{
			["stand"]=
			{
				ticks=1,--how long is each frame shown.
				frames={1},--what frames are shown.
			},
			["walk"]=
			{
				ticks=5,
				frames={2,3,4,5},
			},
			["jump"]=
			{
				ticks=1,
				frames={2},
			},
			["slide"]=
			{
				ticks=1,
				frames={2},
			},
		},

		curanim="walk",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=false,--show sprite be flipped.
		
		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,
		
		uncharge = function(self)
			if (self.charge) then 
				camera_shake = 15
				sfx(2,-1)
				sfx(1)
				self.charge = false

			end
		end,
		--call once per tick.
		update=function(self)
	
			if descent_tracker > 8 then
				descent_tracker = 0
				generator(self.y)
			end
			
			--track button presses
			local bl=btn(0) --left
			local br=btn(1) --right
			
			


			--move left/right
			if bl==true then
				self.dx-=self.acc
				br=false--handle double press
			elseif br==true then
				self.dx+=self.acc
			else
				if self.grounded then
					self.dx*=self.dcc
				else
					self.dx*=self.air_dcc
				end
			end

			--limit walk speed
			if not self.charge then
				self.dx=mid(-self.max_dx,self.dx,self.max_dx)
			end
			
			

			--move in x
			self.x+=self.dx
			
			--hit walls
			if collide_side(self) then
				self:uncharge()
				self.charge = false
			end

			--jump buttons
			self.jump_button:update()
			
			--jump is complex.
			--we allow jump if:
			--	on ground
			--	recently on ground
			--	pressed btn right before landing
			--also, jump velocity is
			--not instant. it applies over
			--multiple frames.
			if self.jump_button.is_down then
				--is player on ground recently.
				--allow for jump right after 
				--walking off ledge.
				local on_ground=(self.grounded or self.airtime<5)
				--was btn presses recently?
				--allow for pressing right before
				--hitting ground.
				local new_jump_btn=self.jump_button.ticks_down<10
				--is player continuing a jump
				--or starting a new one?
				if self.jump_hold_time>0 or (on_ground and new_jump_btn) then
					if(self.jump_hold_time==0)sfx(snd.jump)--new jump snd
					self.jump_hold_time+=1
					--keep applying jump velocity
					--until max jump time.
					if self.jump_hold_time<self.max_jump_press then
						self.dy=self.jump_speed--keep going up while held
					end
				end
			else
				self.jump_hold_time=0
			end

			self.drill_button:update()

			if self.drilling_timer > 0 then
				m_line_particle(self.x+self.cdx*5,self.y+self.cdy*5,10,8)
				self.drilling_timer -= 1
				self.dx = 0
				self.dy = 0
			end

			if self.drilling_timer == 1 then
				music(-1)
				sfx(5)
				for i=0,32 do
					m_line_particle(self.x+self.cdx*5,self.y+self.cdy*5,10,15)
				end
			end

			if not self.ground and not self.charge and self.drilling_timer == 0 then
				local ndx,ndy = vec_normalize(self.dx,self.dy)
				if vec_length(ndx,ndy) > 0.1 then
					self.cdx = ndx*3
					self.cdy = ndy*3
				end
			else
				self.dy = -0.1
			end

			if self.drill_button.is_pressed and not self.grounded and (abs(self.cdx) > 0.3 or abs(self.cdy) > 0.3 ) then
				self.charge = true 
				if rnd(1)<0.5 then
					self.x -= 0.01 -- the CLUTCHIEST CLUTCH
					-- otherwise drilling always fails on the right side
					-- now it SOMETIMES fails on EITHER side, at least there is
					-- no pattern to it!
				end
			else
				--self.jump_hold_time=0
			end

			

			if self.charge then
				sfx(1)
				self.dx = self.cdx
				self.dy = self.cdy
				for i=0,1 do
					m_line_particle(self.x+self.cdx*5,self.y+self.cdy*5,7,7)
				end
				-- break block by collision

				for ix = -8,8 do
					for iy = -8,8 do
						if fget_at(self.x+ix,self.y+iy,7) then
							for i=0,32 do
								m_line_particle(self.x+ix,self.y+iy,13,15)
							end
							sfx(3)
							p1.score += 5
							cmset(flr((self.x+ix)/8),flr((self.y+iy)/8),0)
						end
					end
				end

				-- break block and objects by drill
				for i=0,5 do

					local bx = self.x+self.cdx*5
					local by = self.y+self.cdy*5
					-- break block
					--[[
					if fget_at(bx,by,7) then
						sfx(3) 
						for i=0,64 do
							sfx(2)
							m_line_particle(self.x+bx,self.y+by,13,15)
						end
						p1.score += 5
						--self:uncharge()
						cmset(flr(bx/8),flr(by/8),0)
					end
					]]
					for id,object in pairs(objects) do
						if object.drillable and distance(self.x,self.y,object.x,object.y) < 8 then
							if object.gilded then
								p1.score += object.gilded
								m_text_particle("+"..object.gilded,self.x,self.y)
								if p1.health < 10 then
									p1.health += object.hr or 0
								end
								self.drilling_timer = 30
								self.drilled_sprite = object.drillable
								music(0)
							end
							objects[id] = nil
							
							self:uncharge()
							self.dy = -20
						end
					end
				end
			else
				-- take damage from enemies
				for i,enemy in pairs(objects) do
					if enemy.damaging then
						if distance(self.x,self.y,enemy.x,enemy.y) < 4 then
							objects[i] = nil
							for i=0,4 do
								for i=0,32 do
									local line_x,line_y,line_length = rnd(128),rnd(128),rnd(64)
									rectfill(line_x,line_y,line_x+line_length,line_y,4)
								end
								flip()
							end
							p1.health -= 1
							if p1.health == 0 then
								gameover()
							end
						end
					end
				end
			end

			if fget_at(self.x,self.y,3) then
				self.health -= 1
				if p1.health == 0 then
					gameover()
				end
				cmset(self.x/8,self.y/8,0)
				for i=0,4 do
					for i=0,32 do
						local line_x,line_y,line_length = rnd(128),rnd(128),rnd(64)
						rectfill(line_x,line_y,line_x+line_length,line_y,4)
					end
					flip()
				end
			end
			

			--move in y
			self.dy+=self.grav
			if not self.charge then
				self.dy=mid(-self.max_dy,self.dy,self.max_dy)
			end
			self.y+=self.dy

			--floor
			if not collide_floor(self) then
				self:set_anim("jump")
				self.grounded=false
				self.airtime+=1
			else
				self:uncharge()
				self.charge = false
				
			end

			--roof
			if collide_roof(self) then
				self:uncharge()
				self.charge = false
				
			end

			--handle playing correct animation when
			--on the ground.
			if self.grounded then
				if br then
					if self.dx<0 then
						--pressing right but still moving left.
						self:set_anim("slide")
					else
						self:set_anim("walk")
					end
				elseif bl then
					if self.dx>0 then
						--pressing left but still moving right.
						self:set_anim("slide")
					else
						self:set_anim("walk")
					end
				else
					self:set_anim("stand")
				end
			end

			--flip
			if br then
				self.flipx=false
			elseif bl then
				self.flipx=true
			end

			--anim tick
			self.animtick-=1
			if self.animtick<=0 then
				self.curframe+=1
				local a=self.anims[self.curanim]
				self.animtick=a.ticks--reset timer
				if self.curframe>#a.frames then
					self.curframe=1--loop
				end
			end
			
			camera_y = self.y - 64
			
			descent_tracker += self.dy
			

			if self.y >= 256+64  then
				
				camera_y = 0
				self.y = 64
			end

		end,

		--draw the player
		draw=function(self)
			
			local nx,ny = vec_normalize(self.cdx or 0,self.cdy or 0)
			local rx,ry = 0,0
			if self.charge then
				rx = rnd(4)-2
				ry = rnd(4)-2
			end
			if not self.grounded then
				rspr(120,24,self.x+nx*8-4+rx,self.y+ny*8-4+ry,-vec_angle(nx,ny),1)
			end

			if self.drilling_timer > 0 then
				spr(self.drilled_sprite,self.x+nx*16-4,self.y+ny*16-4)
			end
			
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				false)

		end,
	}

	return p
end

function m_gold(x,y)
	local p=
	{
		x=x,
		y=y,
		dx=0,
		dy=0,
		
		drillable=9,
		gilded=200,
		update = function() end,
		draw = function() 
			spr(9,x-4,y-4)
		end

	}
	return p
end

function m_goldheart(x,y)
	local p=
	{
		x=x,
		y=y,
		dx=0,
		dy=0,
		
		drillable=10,
		gilded=200,
		hr=1,
		update = function() end,
		draw = function() 
			spr(10,x-4,y-4)
		end

	}
	return p
end
descent_tracker = 0
function m_bug(x,y)

	--todo: refactor with m_vec.
	local p=
	{
		timer = 0,
		damaging = true,

		drillable = 42,
		gilded = 1000,

		x=x,
		y=y,

		dx=1,
		dy=0,

		w=8,
		h=8,
		
		max_dx=1,--max x speed
		max_dy=2,--max y speed
		
		--animation definitions.
		--use with set_anim()
		anims=
		{
			["wall"]=
			{
				ticks=15,
				frames={36,37,38,39,40,41},
			},
			["floor"]={
				ticks=15,
				frames={42,43,44,45,46,47}
			}
		},

		curanim="floor",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=false,--show sprite be flipped.
		
		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,
		
		m_right = true,
		--call once per tick.
		update=function(self)
			self.timer += 1
			if self.timer == 15*6 then
				self.timer = 0
				p = m_projectile(self.x,self.y,1.3)
				add(objects,p)
			end
			--move in x

			--anim tick
			self.animtick-=1
			if self.animtick<=0 then
				self.curframe+=1
				local a=self.anims[self.curanim]
				self.animtick=a.ticks--reset timer
				if self.curframe>#a.frames then
					self.curframe=1--loop
				end
			end

		end,

		--draw the enemy
		draw=function(self)
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				false)
		end,
	}

	return p
end
function m_bat(x,y)



	--todo: refactor with m_vec.
	local p=
	{
		damaging = true,

		drillable = 24,
		gilded = 500,

		x=x,
		y=y,

		dx=1,
		dy=0,

		w=8,
		h=8,
		
		max_dx=1,--max x speed
		max_dy=2,--max y speed
		
		--animation definitions.
		--use with set_anim()
		anims=
		{
			["stand"]=
			{
				ticks=1,--how long is each frame shown.
				frames={23},--what frames are shown.
			},
			["walk"]=
			{
				ticks=5,
				frames={23,24,25,26},
			},
		},

		curanim="walk",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=false,--show sprite be flipped.
		
		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,
		
		m_right = true,
		--call once per tick.
		update=function(self)
		
			--move in x
			self.x+=self.dx
			
			if collide_side(self) then
				if self.m_right then
					self.dx = 1
					self.x += 4
					self.flipx=false
				else
					self.dx = -1
					self.x -= 4
					self.flipx=true
				end
				self.m_right = not self.m_right
			end

			--anim tick
			self.animtick-=1
			if self.animtick<=0 then
				self.curframe+=1
				local a=self.anims[self.curanim]
				self.animtick=a.ticks--reset timer
				if self.curframe>#a.frames then
					self.curframe=1--loop
				end
			end

		end,

		--draw the enemy
		draw=function(self)
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				false)
		end,
	}

	return p
end

function m_slime(x,y)

	--todo: refactor with m_vec.
	local p=
	{
		drillable = 27,
		gilded = 200,
		damaging = true,
		x=x,
		y=y,

		dx=1,
		dy=0,

		w=8,
		h=8,
		
		max_dx=1,--max x speed
		max_dy=2,--max y speed

		jump_speed=-1.75,--jump veloclity
		acc=0.05,--acceleration
		dcc=0.8,--decceleration
		air_dcc=1,--air decceleration
		grav=0.15,
		
		anims=
		{
			["stand"]=
			{
				ticks=1,--how long is each frame shown.
				frames={27},--what frames are shown.
			},
			["walk"]=
			{
				ticks=5,
				frames={32,33,34,35},
			},
		},

		curanim="walk",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=false,--show sprite be flipped.
		
		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,
		
		m_right = true,
		--call once per tick.
		update=function(self)
	
			--limit walk speed
			if not self.charge then
				self.dx=mid(-self.max_dx,self.dx,self.max_dx)
			end
			
			self.x+=self.dx
			
			if collide_side(self) then
				if self.m_right then
					self.dx = 1
					self.x += 4
					self.flipx=false
				else
					self.dx = -1
					self.x -= 4
					self.flipx=true
				end
				self.m_right = not self.m_right
			end
			
			self.dy+=self.grav
			self.y+=self.dy

			--floor
			if not collide_floor(self) then
				self.grounded=false
			end

			--anim tick
			self.animtick-=1
			if self.animtick<=0 then
				self.curframe+=1
				local a=self.anims[self.curanim]
				self.animtick=a.ticks--reset timer
				if self.curframe>#a.frames then
					self.curframe=1--loop
				end
			end

		end,

		--draw the player
		draw=function(self)
			local nx,ny = vec_normalize(self.dx,self.dy)
			
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				false)
		end,
	}

	return p
end

function m_scull(x,y)

	--todo: refactor with m_vec.
	local p=
	{
		x=x,
		y=y,

		dx=0,
		dy=1,

		w=8,
		h=8,
		
		max_dx=1,--max x speed
		max_dy=2,--max y speed
		
		--animation definitions.
		--use with set_anim()
		anims=
		{
			["stand"]=
			{
				ticks=1,--how long is each frame shown.
				frames={48},--what frames are shown.
			},
			["walk"]=
			{
				ticks=5,
				frames={48,49},
			},
		},

		curanim="walk",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=false,--show sprite be flipped.
		
		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,
		
		m_down = true,
		--call once per tick.
		update=function(self)
		
			--move in x
			self.y+=self.dy
			
			if collide_floor(self) or collide_roof(self) then
				if self.m_down then
					self.dy = 1
					self.y += 4
					self.flipy=false
				else
					self.dy = -1
					self.y -= 4
					self.flipy=true
				end
				self.m_down = not self.m_down
			end

			--anim tick
			self.animtick-=1
			if self.animtick<=0 then
				self.curframe+=1
				local a=self.anims[self.curanim]
				self.animtick=a.ticks--reset timer
				if self.curframe>#a.frames then
					self.curframe=1--loop
				end
			end

		end,

		--draw the enemy
		draw=function(self)
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				self.flipy)
		end,
	}

	return p
end

function m_projectile(x,y,vel)
	p = {
		damaging=true,
		x=x,
		y=y,
		t=0,
		dx = -cos(cvec_angle(p1.x,p1.y,x,y))*vel,
		dy = -sin(cvec_angle(p1.x,p1.y,x,y))*vel,

		draw = function(self)
			local r = abs(sin(self.t/20)*2)+1
			circfill(self.x,self.y,r,8)
			circfill(self.x,self.y-256,r,8)
		end,
		update = function(self)
			self.t+=1
			if self.t>60 then
				del(objects,self)
			end
			self.x+=self.dx
			self.y+=self.dy
		end
		
	}
	return p
end
function m_crab(x,y)

	--todo: refactor with m_vec.
	local p=
	{
		x=x,
		y=y,

		dx=0,
		dy=0,

		w=16,
		h=24,
		
		--animation definitions.
		--use with set_anim()
		anims=
		{
			["stand"]=
			{
				ticks=1,--how long is each frame shown.
				frames={153},--what frames are shown.
			},
		},

		curanim="stand",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=false,--show sprite be flipped.
		
		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,

		--draw the enemy
		draw=function(self)
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				false)
			spr(frame,
				self.x-(self.w/16),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				true,
				false)
		end,
	}

	return p
end

function m_crab_hand_left(x,y)

	--todo: refactor with m_vec.
	local p=
	{
		x=x,
		y=y,

		dx=0,
		dy=0,

		w=16,
		h=16,
		
		ttt=0,
		
		--animation definitions.
		--use with set_anim()
		anims=
		{
			["stand"]=
			{
				ticks=25,--how long is each frame shown.
				frames={148,150},--what frames are shown.
			},
		},


		curanim="stand",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=false,--show sprite be flipped.
		
		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,

		update=function(self)
			self.ttt+=0.01
			self.dx = sin(self.ttt)/5
			self.dy = cos(self.ttt)/5
			
			self.x += self.dx
			self.y += self.dy
			--anim tick
			self.animtick-=1
			if self.animtick<=0 then
				self.curframe+=1
				local a=self.anims[self.curanim]
				self.animtick=a.ticks--reset timer
				if self.curframe>#a.frames then
					self.curframe=1--loop
				end
			end

		end,
		--draw the enemy
		draw=function(self)
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				false)
		end,
	}

	return p
end

function m_crab_hand_right(x,y)

	--todo: refactor with m_vec.
	local p=
	{
		x=x,
		y=y,

		dx=0,
		dy=0,

		w=16,
		h=16,
		
		ttt = 0.25,
		
		--animation definitions.
		--use with set_anim()
		anims=
		{
			["stand"]=
			{
				ticks=25,--how long is each frame shown.
				frames={148, 150},--what frames are shown.
			},
		},

		curanim="stand",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=true,--show sprite be flipped.
		
		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,
		
		update=function(self)
			self.ttt+=0.01
			self.dx = sin(self.ttt)/5
			self.dy = cos(self.ttt)/5
			
			self.x += self.dx
			self.y += self.dy
			--anim tick
			self.animtick-=1
			if self.animtick<=0 then
				self.curframe+=1
				local a=self.anims[self.curanim]
				self.animtick=a.ticks--reset timer
				if self.curframe>#a.frames then
					self.curframe=1--loop
				end
			end

		end,

		--draw the enemy
		draw=function(self)
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				false)
		end,
	}

	return p
end

--make the camera.
function m_cam(target)
	local c=
	{
		tar=target,--target to follow.
		pos=m_vec(target.x,target.y),
		
		--how far from center of screen target must
		--be before camera starts following.
		--allows for movement in center without camera
		--constantly moving.
		pull_threshold=16,

		--min and max positions of camera.
		--the edges of the level.
		pos_min=m_vec(64,64),
		pos_max=m_vec(320,64),
		
		shake_remaining=0,
		shake_force=0,

		update=function(self)

			self.shake_remaining=max(0,self.shake_remaining-1)
			
			--follow target outside of
			--pull range.
			if self:pull_max_x()<self.tar.x then
				self.pos.x+=min(self.tar.x-self:pull_max_x(),4)
			end
			if self:pull_min_x()>self.tar.x then
				self.pos.x+=min((self.tar.x-self:pull_min_x()),4)
			end
			if self:pull_max_y()<self.tar.y then
				self.pos.y+=min(self.tar.y-self:pull_max_y(),4)
			end
			if self:pull_min_y()>self.tar.y then
				self.pos.y+=min((self.tar.y-self:pull_min_y()),4)
			end

			--lock to edge
			if(self.pos.x<self.pos_min.x)self.pos.x=self.pos_min.x
			if(self.pos.x>self.pos_max.x)self.pos.x=self.pos_max.x
			if(self.pos.y<self.pos_min.y)self.pos.y=self.pos_min.y
			if(self.pos.y>self.pos_max.y)self.pos.y=self.pos_max.y
		end
	}
end
depth = 0
function generator(current_y)
	-- tile numbers
	depth += 1
	sfx(6)

	local now = flr(current_y/8)
	local cutoff = now-10
	local target = now+18

	

	for i=1,14 do
		for yi = 0,2 do
			cmset(i,cutoff-yi,75)
		end
		for yi = 3,4 do
			cmset(i,cutoff-yi,0)
		end
		cmset(i,cutoff+1,71)
	end

	cmset(flr(rnd(16)),target,73)
	cmset(flr(rnd(16)),target,74)

	-- breakable
	if target%8<4 then
		
		local platform_budget = rnd(3)+3
		while platform_budget > 1 do
			local platform_spending = rnd(platform_budget)
			platform_budget -= platform_spending
			platform(rnd(8)+4,target,platform_spending,76)
			
		end
	end
	
	-- unbreakable
	if target%3==0 then
		
		local platform_budget = rnd(3)+3
		while platform_budget > 1 do
			local platform_spending = rnd(platform_budget)
			platform_budget -= platform_spending
			platform(rnd(8)+4,target,platform_spending,67)
			
		end
	end

	if rnd(10)<1 then
		cmset(1,target,82)
		cmset(14,target,82)
	end
	
	local spawn_x_tile = flr(rnd(13)+1)
	
	if rnd(10-depth/50)<1 and not fget_at(spawn_x_tile*8,(target-1)*8,0) then
		local g = m_gold(spawn_x_tile*8+4,(target-1)*8+4)
		cmset(spawn_x_tile,target-1,76)
		add(objects,g)
	end

	if rnd(30)<1 and not fget_at(spawn_x_tile*8,(target-1)*8,0) then
		local g = m_goldheart(spawn_x_tile*8+4,(target-1)*8+4)
		cmset(spawn_x_tile,target-1,76)
		add(objects,g)
	end

	if rnd(100-depth/20)<1 and not fget_at(2*8,(target-1)*8,0) then
		local b = m_bug(2*8-4,target*8)
		add(objects,b)
	end

	if rnd(50-depth/10)<1 and not fget_at(14*8,(target-1)*8,0) then
		local b = m_bug(15*8-4,target*8)
		b.flipx = true
		add(objects,b)
	end

	local batpos = flr(rnd(14)+1)*8
	if rnd(30-depth/10)<1 and not fget_at(batpos,(target-1)*8,0) then
		local bat = m_bat(batpos,target*8)
		add(objects,bat)
	end

	local spos = flr(rnd(14)+1)*8
	if rnd(20-depth/30)<1 and not fget_at(spos,(cutoff+5)*8,0) then
		local slime = m_slime(spos,cutoff*8+8*4)
		add(objects,slime)
	end

	cmset(0,target,65)
	cmset(15,target,66)
end

function platform(x,y,w,t)
	for i=0,w-1 do
		cmset(x+i,y,t)
		cmset(x-i,y,t)
	end
end

--game flow
--------------------------------

--reset the game to its initial
--state. use this instead of
--_init()
idletime = 0
function reset()
	reload()
	depth = 0
	idletime = 0
	objects = {}
	particles = {}
	ticks=0

	p1=m_player(62,100)
	
	p1:set_anim("walk")



	p1:set_anim("walk")
	
end

--p8 functions
--------------------------------

function _init()
	reset()
end


function setgamestate(state)
	_update60 = gamestates[state].update
	_draw = gamestates[state].draw
end

function updategame()
	ticks+=1
	p1:update()
	idletime += 1
	for i=0,5 do
		if btn(i) then
			idletime = 0
		end
	end
	if idletime > 60*30 then
		reset()
	end
	for i,v in pairs(objects) do
		v:update()
		if fget_at(v.x,v.y,6) then
			del(objects,v)
		end
		if v.x < 0 or v.x > 127 or v.y > 512 then
			del(objects,v)
		end
	end
	for i,v in pairs(particles) do
		v:update()
	end

end
camera_shake = 0
ttt = 0


function drawgame()
	ttt += 0.5
	--[[for i=0,63 do
		memset(0x6000+0x40*(i)*2+flr(ttt)%2*0x40,0x00,0x40)
	end]]
	cls(0)
	-- world
	local shx,shy = 0,0
	if camera_shake > 0 then
		shx = rnd(6)-3
		shy = rnd(6)-3
		camera_shake -= 1
	end
	camera(0+shx,camera_y+shy) 
	
	map(0,0,0,0,16,32) -- real
	map(0,0,0,256,16,32) -- bottom_phantom
	map(0,0,0,-256,16,32) -- top_phantom
	
	p1:draw()


	for i,v in pairs(objects) do
		v:draw()
	end
	for i,v in pairs(particles) do
		v:draw()
	end

	
	
	--hud
	camera(0,-1)
	--[[for ix = 0,16 do
		for iy=0,32 do
			if mget(ix,iy) > 0 then
				pset(ix,iy,7)
			end
		end
	end]]

	for i=1,10 do
		if i <= p1.health then
			spr(6,i*8-8,6)
		else
			spr(7,i*8-8,6)
		end
	end

	local scorestring = p1.score .. ""

	while #scorestring < 6 do
		scorestring = "0" .. scorestring
	end

	printo(scorestring,104,1,10,1,1)

	--spr(p1.drilled_sprite or 0, 0,0)

	printo("???miner vitalya???",0,1,10,1,0)

	print("anton@cardboardbox demo",0,122,1)

end

--[[
	function printc(
	str,x,y,
	col,col_bg,
	special_chars)
]]

function gameoverdraw()
	for x=0,127 do
		for y=0,127 do
			if rnd(20)<1 then
				pset(x,y,pget(x,y-1))
			end
		end
	end
	if gameovertime > 15 then
		printc("game over",64,64,8,1,0)
	end
	if gameovertime > 30 then
		printc("final score",64,64+8,8,1,0)
	end
	if gameovertime > 45 then
		local scorestring = gameoverscore .. ""

		while #scorestring < 6 do
			scorestring = "0" .. scorestring
		end
		printc(scorestring,64,64+16,8,1,0)
	end
	
	flip()
end

function gameoverupdate()
	gameovertime +=1
	if gameovertime > 90 then
		reset()
		setgamestate("game")
	end
end

gamestates = {
	gameover = {
		draw = gameoverdraw,
		update = gameoverupdate
	},
	game = {
		draw = drawgame,
		update = updategame
	}
}

gameoverscore = 0
gameovertime = 0
function gameover()
	gameovertime += 1
	gameoverscore = p1.score
	setgamestate("gameover")
end



setgamestate("game")
__gfx__
01234567000000000000000000099000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
89abcdef0009900000099000009aa900009aa9000009900001101100011011000000000000aaa000099099000000000000000000000000000000000000000000
00700700009aa900009aa9000077770000777700009aa9001881881011111110000000000077a9009aa9aa900000000000000000000000000000000000000000
0007700000777700007777000070700000707000007777001878881011711110000000000a77aa009a7aaa900000000000000000000000000000000000000000
0007700000707000007070000077770000777700007070001888881011111110000000000aa7aaa09aaaaa900000000000000000000000000000000000000000
00700700007777000077770000777770077777000077770001888100011111000000000000aaaaa009aaa9000000000000000000000000000000000000000000
000000000077770000777770070000000000007007777700001810000011100000000000009aaa90009a90000000000000000000000000000000000000000000
0000000000700700007000000000000000000000000007000001000000010000000000000099a900000900000000000000000000000000000000000000000000
81709a40000000000000000000099000000990000000000000099900000000000000000000000000000000000000000000000000000000000000000000000000
444444400009900000099000009aa900009aa90000099000009aaa90000000000000000000000000000000000000000000000000000000000000000000000000
00000000009aa900009aa9000077770000777700009aa90000a070a0080080000800800008008000080080000000000000000000000000000000000000000000
00000000007777000077770000707000007070000077770000777770707700700077000000770000007700000000000000000000000000000000777000007770
00000000007070000070700000777700007777000070700000777770077877000778700007787000077870000770000007700000077000000007070700070707
00000000007777000077770000777770077777000077770000788880000000007000070007007000700007000780770007807700078077000007070700870707
00000000007777000077777007000000000000700777770000808080000000000000000070000700000000000007887000078870000788700088777808887778
00000000007007000070000000000000000000000000070000000000000000000000000000000000000000000008008000080008008000800888888888888880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000007700000077000000000000000000000000000000000000000000000000000000700000007000000080000000800000008000000070000
00077000007877000078770000787700000000000000000000000000000000000000000000000000107070001080700010807000108080001070800010708000
00787700078777700787777007877770007007000070070000700700008008000080080000800800770000007700000077000000770000007700000077000000
07877770077777700777777007777770070000700700007008000080080000800800008007000070770000007700000077000000770000007700000077000000
08777780087777800087780008777780007007000080080000800800008008000070070000700700107070001080700010807000108080001070800010708000
00888800008888000008800000888800000770000007700000077000000770000007700000077000000700000007000000080000000800000008000000070000
00000000000000000000000000000000001771000017710000177100001771000017710000177100000000000000000000000000000000000000000000000000
00000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
80000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000767681
88000000888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006767618
88aa000088aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000076767681
8a00a0008a00a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000076767618
8aaaa0008aaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006767681
8a00a0008a00a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000767618
88aa000008aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100110100115555515000000155500dd150000dddddddd000051dd11111111d1d500000000000000000000111111110dddddd0000000000000000000000000
1ff11ff1000051555551105001551550d1115000d1d1d1d100511d1d15111511dd115000011000000000010010011111dddddddd000000000000000000000000
49944994050115555515000001515150dd1500001d1d1d1d000511dd11111111d1d50000011000000000000010011111dd11dddd000000000000000000000000
01100110000051555551100100155500d11150505111151500511d1d11111111dd115000000000000000000011111011dd11dddd000000000000000000000000
00000000100115555515000005000150dd11151501515050000511dd51515151d1d11500000001000000000011111101dddddd1d000000000000000000000000
00000000000051555551105055501551d1d1d1d10505000000005d1d15151515dd115000000000000000000011111111dddddddd000000000000000000000000
00000000050115555515000015501515dd1d1d1d00000000000511dd55555555d1d11500001000000000001011110111dd1ddddd000000000000000000000000
000000000000515555511001555001550ddddddd0000000000005d1d55555555dd1500000000000000000000111111110dddddd0000000000000000000000000
000011d0d111000080000008000000000001111ddd1110000001111ddd1110000000111011110000000000000000000000000000000000000000000000000000
0011ddd0ddd101000880088000000000001ddd1000ddd100001ddd1000ddd1000011111011110100000000000000000000000000000000000000000000000000
001dddd0dddd0110088888200000000001d0000ee0000d1001d0000660000d100011111011110110000000000000000000000000000000000000000000000000
00000009000000000087820000000000000888800aaa0d100008888007770d100000000000000000000000000000000000000000000000000000000000000000
11dd0d9a9d0ddd10008882000000000010c0880cc0a0000010508807707000001111011111011110000000000000000000000000000000000000000000000000
11dd09aaa90dd1100882222000000000d0c0800cc00bbb00d0508007700555001111011000001110000000000000000000000000000000000000000000000000
11dd09a7a90dd1110820022000000000d00f0cc00cc0b0d1d0070770077050d11111010000000111000000000000000000000000000000000000000000000000
000000a7a00000008000000200000000d0ff0cc00cc000d1d0770770077000d10000000500050000000000000000000000000000000000000000000000000000
011dd0fff0dd0d11000000000000000000fff00cc008800000777007700880000111100000000111000000000000000000000000000000000000000000000000
011dd04f40dd0d1100000000000000001d0f090cc088800d1d0706077088800d0111100000000111000000000000000000000000000000000000000000000000
0011d04440dd011000000000000000000100090cc0880c0d010006077088070d0011101110110110000000000000000000000000000000000000000000000000
0000000440000000000000000000000001d09990c000c0d101d06660700070d10000000000000000000000000000000000000000000000000000000000000000
00110100401111000000000000000000001000000a00001000100000070000100011011110111100000000000000000000000000000000000000000000000000
0001011000111000000000000000000000110d00a01ddd1000110d00701ddd100001011110111000000000000000000000000000000000000000000000000000
00000111100000000000000000000000000101d0a0111100000101d0701111000000011110000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000111d000000000000111d00000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000500500500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000900000000000550600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000009a90000000000605500000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000a7a0000000000600500000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000055500000000000009f90000000000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000555550000000000001400000000000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000050550005000000001400000335000000600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000555500055005000000100003555300000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011177700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007777000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000
00000000778000000000000000000000000000000000000000000008888000000000000000000888000000000000000000000000000000000000000000000000
00000000088000000000000000000000000000008880000000000088880000000000000000000880000000000000000000000000000000000000000000000000
00000550088000000000000000000000000000888800000000000888800000000000000000000880050000000000000000000000000000000000000000000000
00000055088000000000000000000000000008888800000000008888800000000000000000000800550000000000000000000000000000000000000000000000
50050055088000000000000000000000000088888000000000008888000000000000000000000805500500000000000000000000000000000000000000000000
50055005888000000000000000000000000888880000000000088888000000000000000000000888505500500000000000000000000000000000000000000000
50055588888800000000000000000000000888880880000000088880000000000000000000008888805500500000000000000000000000000000000000000000
58000588888800000000000000000000008888880088000000888880000008000000000000008888885005500000000000000000000000000000000000000000
88888888888800000000000000000000008888880088000000888888000088000000000000008888888888880000000000000000000000000000000000000000
88888888888800000000000000000000008888888088800000888888000088000000000000008888888888880000000000000000000000000000000000000000
88888888888000000000000000000000008888888008800000888888800888000000000000008888888888880000000000000000000000000000000000000000
88888888880000000000000000000000000888888808800000088888888880000000000000008888888888880000000000000000000000000000000000000000
88888888880000000000000000000000000088888888800000008888888880000000000000008888888888880000000000000000000000000000000000000000
88888888880000000000000000000000000008888888000000000888888800000000000000000888888888880000000000000000000000000000000000000000
88888888800000000000000000000000000000008880000000000000888000000000000000000888888888880000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000008888888880000000000000000000000000000000000000000
88888000880000000000000000000000000000000000000000000000000000000000000000000080008888880000000000000000000000000000000000000000
88888888880000000000000000000000000000000000000000000000000000000000000000000088888888880000000000000000000000000000000000000000
88888888880000000000000000000000000000000000000000000000000000000000000000000088888888880000000000000000000000000000000000000000
88888888800000000000000000000000000000000000000000000000000000000000000000000088888888880000000000000000000000000000000000000000
88888888800000000000000000000000000000000000000000000000000000000000000000000008888888880000000000000000000000000000000000000000
88888888800000000000000000000000000000000000000000000000000000000000000000000000888888880000000000000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000888888880000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007770770070700000000077707770077077700770000077707000777077707770077077707770777077700000000000000000000000
00000000000000000000007070707070700000000077700700700070707070000070707000707007007000707070707770700070700000000000000000000000
00000000000000000000007770707070700000000070700700700077007070000077707000777007007700707077007070770077000000000000000000000000
00000000000000000000007070707077700000000070700700700070707070000070007000707007007000707070707070700070700000000000000000000000
00000000000000000000007070777007000700000070707770077070707700000070007770707007007000770070707070777070700000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d11150000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000
00dd1500000000505000005050000050500000505000005050000050500000505000005050000050500000505001100000000050500000505000005050000050
00d11150500505151005051510050515100505151005051510050515100505151005051510050515100505151000000000050515100505151005051510050515
00dd1115155151111551511115515111155151111551511115515111155151111551511115515111155151111500000100515111155151111551511115515111
00d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d100000000d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1
00dd1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d001000001d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
000ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000dddddddddddddddddddddddddddddd
005005005000000000000000000000000000000000000000000000000050050050000000000000000050050050d1d50000000051dd0000000000000000000051
005506000000000000000000000000000000000000000000000000000055060000000000000000000055060000dd11500000511d1d000001000000900000511d
006055000000000000000000000000000000000000000000000000000060550000000000000000000060550000d1d50000000511dd000000000009a900000511
006005000000000000000000000000000000000000000000000000000060050000000000000000000060050000dd11500000511d1d00000000000a7a0000511d
000006000000000000000000000000000000000000000000000000000000060000000000000000000000060000d1d11500000511dd000000000009f900000511
000006000000000000000000000000000000000000000000000000000000060000000000000000000000060000dd11500000005d1d000000000001400000005d
000006000000000000000000000000000000000000000000000000000000060000000000000000000000060000d1d11500000511dd0000001000014000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd15000000005d1d000000000000100000005d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000051dd0000000000000000000051
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d011000000000000000511d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000511dd0110000000000000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d000000000000000000511d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0000010000000000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000005d1d000000000000000000005d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0010000000000000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd15000000005d1d000000000000000000005d
100110011001100110000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000051dd0000000000000000000051
f11ff11ff11ff11ff1000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d000000000000900000511d
944994499449944994000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000511dd000000000009a900000511
100110011001100110000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d00000000000a7a0000511d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd000000000009f900000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000005d1d000000000001400000005d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0000000000014000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd15000000005d1d000000000000100000005d
d0d111000000000000000000000000000001100110000000000110011000000000011001100000000001100110d1d50000000051dd0000000000000000000051
d0ddd101000000000000000000000000001ff11ff1000000001ff11ff1000000001ff11ff1000000001ff11ff1dd11500000511d1d000001000000000000511d
d0dddd011000000000000000000000000049944994000000004994499400000000499449940000000049944994d1d50000000511dd0000000000000000000511
090000000000000000000000000000000001100110000000000110011000000000011001100000000001100110dd11500000511d1d000000000000000000511d
9a9d0ddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0000000000000000000511
aaa90dd11000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000005d1d000000000000000000005d
a7a90dd11100000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0000001000000000000511
a7a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd15000000005d1d000000000000000000005d
fff0dd0d1100000000000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000051dd0000000000000000000051
4f40dd0d1100000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d011000000000900000511d
4440dd011000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000511dd011000000009a900000511
044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d00000000000a7a0000511d
004011110000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd000001000009f900000511
100011100000000000000000000000000000000000000051110000000000000000000000000000000000000000dd11500000005d1d000000000001400000005d
111000000000000000000000000000000000000000000061711000000000000000000000000033500000000000d1d11500000511dd0010000000014000000511
000000000000000000000000000000000000000000000627871700000000000000000000000355530000000000dd15000000005d1d000000000000100000005d
00000000000000000000000000000000000000000000005771600000000dddddddddddddddddddddd000000000d1d50000000051dd0000000000000000000051
0000000000000000000000000000000000000000000000066600000000dd1d1d1dd1d1d1d1d1d1d1dd00000000dd11500000511d1d000000000000000000051d
0000000000000000000000000000000000000000000000059900000000d1d111111d1d1d1d1d1d1d1d00000000d1d50000000511dd0000505000005050000051
0000000000000000000000000000000000000000000000055000000000dd11151551111515515111dd00000000dd11500000511d1d050515100505151005051d
0000000000000000000000000000000000000000000000440000000000d1d15050015150500505111d00000000d1d11500000511dd5151111551511115515111
0000000000000000000000000000000000000000000000000000000000dd15000005050000000051dd00000000dd11500000005d1dd1d1d1d1d1d1d1d111111d
0000500000000000000000000000000000000000000000000000000000d1d15000000000000005111d00000000d1d11500000511dd1d1d1d1d1d1d1d1dd1d1d1
0005500500000000000000000000000000000000000000000000000000dd15000000000000000051dd00000000dd15000000005d1ddddddddddddddddddddddd
ddddddddd0000000000000000000000000000000000000000000000000d1d5000000000000000051dd00000000d1d50000000051dd5005005000000000000000
1dd1d1d1dd000000000000000000000000000000000000000000000000dd1150000110000000511d1d00000000dd11500000511d1d5506000000000000000000
111d1d1d1d000000000000000000000000000000000000000000000000d1d5000001100000000511dd00000000d1d50000000511dd6055000000000000000000
15515111dd000000000000000000000000000000000000000000000000dd1150000000000000511d1d00000000dd11500000511d1d6005000000000000000000
500505111d000000000000000000000000000000000000000000000000d1d1150000000100000511dd00000000d1d11500000511dd0006000000000000000000
00000051dd000000000000000000000000000000000000000000000000dd1150000000000000005d1d00000000dd11500000005d1d0006000000000000000000
000005111d000000000000000000000000000000000000000000000000d1d1150000100000000511dd00000000d1d11500000511dd0006000000000000000000
00000051dd000000000000000000000000000000000000000000000000dd1500000000000000005d1d00000000dd15000000005d1d0000000000000000000000
00000051dd000000000000000000000000000011d0d111000000000000d1d5000000000000000051dd01100110d1d50000000051dd0000000000000000000000
0000051d1d0000000000000000000000000011ddd0ddd1010000000000dd1150000000010000511d1d1ff11ff1dd11500000511d1d0000000000000000000000
00000051dd000000000000000000000000001dddd0dddd011000000000d1d5000000000000000511dd49944994d1d50000000511dd0000000000000000000000
5005051d1d000000000000000000000000000000090000000000000000dd1150000000000000511d1d01100110dd11500000511d1d0000000000000000000000
15515111dd00000000000000000000000011dd0d9a9d0ddd1000000000d1d1150000000000000511dd00000000d1d11500000511dd0000000000000000000000
d111111d1d00000000000000000000000011dd09aaa90dd11000000000dd1150000000000000005d1d00000000dd11500000005d1d0000000000000000000000
1dd1d1d1dd00000000000000000000000011dd09a7a90dd11100000000d1d1150000000010000511dd00000000d1d11500000511dd0000000000000000000000
ddddddddd0000000000000000000000000000000a7a000000000000000dd1500000000000000005d1d00000000dd15000000005d1d0000000000000000000000
0000000000000000000000000000000000011dd0fff0dd0d1100000000d1d5000000000000000051dd00000000d1d50000000051ddddddddd000000000000000
0000000000000000000000000000000000011dd04f40dd0d1100000000dd1150000110000000511d1d00000000dd11500000511d1dd1d1d1dd00000000000000
00000000000000000000000000000000000011d04440dd011000000000d1d5000001100000000511dd00000000d1d50000000511dd1d1d1d1d00000000000000
0000000000000000000000000000000000000000044000000000000000dd1150000000000000511d1d00000000dd11500000511d1d515111dd00000000000000
0000000000000000000000000000000000001101004011110000000000d1d1150000000100000511dd00000000d1d11500000511dd0505111d00000000000000
0000000000000000000000000000000000000101100011100000000000dd1150000000000000005d1d00000000dd11500000005d1d000051dd00000000000000
0000000000000000000000000000000000000001111000000000000000d1d1150000100000000511dd00000000d1d11500000511dd0005111d00000000000000
0000000000000000000000000000000000000000000000000000000000dd1500000000000000005d1d00000000dd15000000005d1d000051dd00000000000000
0000000000000000000000000000000000000000000000000000000000d1d5000000000000000051dd00000000d1d50000000051dd00000000ddddddd0000000
0000000000000000000000000000000000000000000000000000000000dd1150000000010000511d1d00000000dd11500000511d1d01100000d1d1d1dd000000
0000000000000000000000000000000000000000000000000000000000d1d5000000000000000511dd00000000d1d50000000511dd011000001d1d1d1d000000
0000000000000000000000000000000000000000000000000000000000dd1150000000000000511d1d00000000dd11500000511d1d00000000515111dd000000
0000000000000000000000000000000000000000000000000000000000d1d1150000000000000511dd00000000d1d11500000511dd000001000505111d000000
0000000000000000000000000000000000000000000000000000000000dd1150000000000000005d1d00000000dd11500000005d1d00000000000051dd000000
0000000000000000000000000000000000003350000050000000000000d1d1150000000010000511dd00000000d1d11500000511dd001000000005111d000000
0000000000000000000000000000000000035553000550050000000000dd1500000000000000005d1d00000000dd15000000005d1d00000000000051dd000000
000000000000000000000000000dddddddddddddddddddddd000000000d1d5000000000000000051dd00000000d1d50000000051dd0000000000000000dddddd
00000000000000000000000000dd1d1d1dd1d1d1d1d1d1d1dd00000000dd1150000110000000511d1d00000000dd11500000511d1d0000000000000100d1d1d1
00000000000000000000000000d1d111111d1d1d1d1d1d1d1d00000000d1d5000001100000000511dd00000000d1d50000000511dd00000000000000001d1d1d
00000000000000000000000000dd11151551111515515111dd00000000dd1150000000000000511d1d00000000dd11500000511d1d0000000000000000515111
00000000000000000000055500d1d15050015150500505111d00000000d1d1150000000100000511dd00000000d1d11500000511dd0000000000000000050511
00000000000000000000555550dd15000005050000000051dd00000000dd1150000000000000005d1d00000000dd11500000005d1d0000000000000000000051
00000000000000000000050550d1d15000000000000005111d00000000d1d1150000100000000511dd00000000d1d11500000511dd0000000000000010000511
00000000000000000000555500dd15000000000000000051dd00000000dd1500000000000000005d1d00000000dd15000000005d1d0000000000000000000051
0000000000000000000ddddddd0000000000000000000051dd00000000dd15000000000000000051dd01100110d1d50000000051dd0000000000000000000000
000000000000000000dd1d1d1d000001000000010000511d1d00000000d11150000000000000051d1d1ff11ff1dd11500000511d1d0000000000000000011000
000000000000000000d1d111110000000000000000000511dd00000000dd15000000005050000051dd49944994d1d50000000511dd0000000000000000011000
000000000000000000dd111515000000000000000000511d1d00000000d11150500505151005051d1d01100110dd11500000511d1d0000000000000000000000
000000000000000000d1d150500000000000000000000511dd00000000dd11151551511115515111dd00000000d1d11500000511dd0000000000000000000001
000000000000000000dd150000000000000000000000005d1d00000000d1d1d1d1d1d1d1d111111d1d00000000dd11500000005d1d0000000000000000000000
000000000000335000d1d150000000001000000010000511dd00000000dd1d1d1d1d1d1d1dd1d1d1dd00000000d1d11500000511dd0000000000000000001000
000000000003555300dd150000000000000000000000005d1d000000000dddddddddddddddddddddd000000000dd15000000005d1d0000000000000000000000
00000000000ddddddd000000000000000000000000000051dd0000000000000000500500500000000000000000d1d50000000051dd0000000000000000000000
0000000000dd1d1d1d01100000000000000110000000511d1d0000000000000000550600000000000000000000dd11500000511d1d0110000000000000000000
0000000000d1d11111011000000000000001100000000511dd0000000000000000605500000000000000000000d1d50000000511dd0110000000000000000000
0000000000dd11151500000000000000000000000000511d1d0000000000000000600500000000000000000000dd11500000511d1d0000000000000000000000
0000000000d1d15050000001000000000000000100000511dd0000000000000000000600000000000000000000d1d11500000511dd0000010000000000000000
0000000000dd15000000000000000000000000000000005d1d0000000000000000000600000000000000000000dd11500000005d1d0000000000000000000000
0000500000d1d15000001000000000000000100000000511dd0000000000335000000600000000000000335000d1d11500000511dd0010000000000000000000
0005500500dd15000000000000000000000000000000005d1d0000000003555300000000000000000003555300dd15000000005d1d0000000000000000000000
ddddddddddd1d50000000000000000000000000000000051dddddddddddddddddddddddddddddddddddddddddddddddddd00000000dddddddddddddddddddddd
d1d1d1d1d1dd11500000000000000001000000010000511d1dd1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d100000000d1d1d1d1d1d1d1d1d1d1d1
1d1d1d1d1dd1d50000000000000000000000000000000511dd1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d000000001d1d1d1d1d1d1d1d1d1d1d
1551111515dd11500000000000000000000000000000511d1d511115155111151551111515511115155111151551111515000000005111151551111515511115
5001515050d1d11500000000000000000000000000000511dd015150500151505001515050015150500151505001515050000000000151505001515050015150
0005050000dd11500000000000000000000000000000005d1d050500000505000005050000050500000505000005050000000000000505000005050000050500
0000000000d1d11500000000000000001000000010000511dd000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000dd15000000000000000000000000000000005d1d000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002010101010101010100004081000000000008000000000000000000000000000000000000000000000000000000000001010000000100000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4100000000000000000000000000004244444444444444444444444444444471717171717171000000007171717171710000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000444747474747474444474749474747474743000000004447474747490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000770000000000007700007748464a75460000000000000000487549480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
410000000000000000000000000000420000000000000000000000000000004846497146000000000000000048494a480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004246404040404000000000000000000048460075460000000000000000487500480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004246000050510000004000400040004048464a71460000000000000000484a49480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
410000000000000000000000000000424600006061000000000000000076004846497546000000000000000048754a480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004246000076740000000000004145420048464747430000000000000000444747480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004246000041420000000000004849460048467700000000000000000000007700480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
410000000000000000000000000000424600004443000000505100484a464048460000005051000000005051000000480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004246000000000000006061004849460048464200006061000000006061000041480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
410000000000000000000000000000424600000000000000767400484a46004846494200000000545500000000414a480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
410000000000000000000000000000424300000000007341454200484946004846704a420000006465000000414970480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41000000000000000000000000000042000000000076414a4a460044474340484670704942000000000000414a7070480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000744149704946007677007648464970704a4200737400414970704a480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
41000000000000000000000000000042454545454548704a4a46454545454545004545454545454545454545454545000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4150510000000000000000000050514200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4160610000000000000000000060614200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
414c4c4c4c4c4c4c4c4c4c4c4c4c4c4200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4100000000000000000000000000004200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010600000d051130511b0512505100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130100000a050160500f050160501d0000a05012050140500a05021000120502300014050210000f0500a05024000130500d0500000000000110500a05009050100500f050080000d05006050080000800008000
a1030000006720067214372133721237212372103720f3720d3720d3720c3520b3520a35209352073520435202352013520030200302003020030200302003020030200302003020030200302003020030200302
000300001f65023600306503260039650396002865000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b50200050d76014760157501774018740007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
2b0600002805328053280532804028030220202202028010280002800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c70100000a03007031030310103100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000
010d00001305200000000000c052000000c0520e05200000000000e052000000e0521005200000000001005200000100521105200000000001105200000110521305200000000001305200000130521305213052
001000001305213052130421304213032130321302213022130121301200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 04424344
00 07094344
00 08424344

