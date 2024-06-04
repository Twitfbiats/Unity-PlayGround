Shader "Custom/CoolShader"
{
    Properties 
    {
        _FloatVariable ("Float Variable", Float) = 1.0 // Example float property
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 fragCoord : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.fragCoord = ComputeScreenPos(o.pos); // Calculate screen coordinates
                return o;
            }

            float _FloatVariable;

            float heightMap(in float2 p) { 
    
                p *= 3.;
                
                // Hexagonal coordinates.
                float2 h = float2(p.x + p.y*.57735, p.y*1.1547);
                
                // Closest hexagon center.
                float2 f = frac(h); h -= f;
                float c = frac((h.x + h.y)/3.);
                h =  c<.666 ?   c<.333 ?  h  :  h + 1.  :  h  + step(f.yx, f); 
            
                p -= float2(h.x - h.y*.5, h.y*.8660254);
                
                // Rotate (flip, in this case) random hexagons. Otherwise, you'd have a bunch of circles only.
                // Note that "h" is unique to each hexagon, so we can use it as the random ID.
                c = frac(cos(dot(h, float2(41, 289)))*43758.5453); // Reusing "c."
                p -= p*step(c, .5)*2.; // Equivalent to: if (c<.5) p *= -1.;
                
                // Minimum squared distance to neighbors. Taking the square root after comparing, for speed.
                // Three partitions need to be checked due to the flipping process.
                p -= float2(-1, 0);
                c = dot(p, p); // Reusing "c" again.
                p -= float2(1.5, .8660254);
                c = min(c, dot(p, p));
                p -= float2(0, -1.73205);
                c = min(c, dot(p, p));
                
                return sqrt(c);
                
                // Wrapping the values - or folding the values over (abs(c-.5)*2., cos(c*6.283*1.), etc) - to produce 
                // the nicely lined-up, wavy patterns. I"m perfoming this step in the "map" function. It has to do 
                // with coloring and so forth.
                //c = sqrt(c);
                //c = cos(c*6.283*1.) + cos(c*6.283*2.);
                //return (clamp(c*.6+.5, 0., 1.));
            
            }
            
            // Raymarching an XY-plane - raised a little by the hexagonal Truchet heightmap. Pretty standard.
            float map(float3 p){
                
                
                float c = heightMap(p.xy); // Height map.
                // Wrapping, or folding the height map values over, to produce the nicely lined-up, wavy patterns.
                c = cos(c*6.283*1.) + cos(c*6.283*2.);
                c = (clamp(c*.6+.5, 0., 1.));
            
                
                // Back plane, placed at float3(0., 0., 1.), with plane normal float3(0., 0., -1).
                // Adding some height to the plane from the heightmap. Not much else to it.
                return 1. - p.z - c*.025;
            
                
            }
            
            // The normal function with some edge detection and curvature rolled into it. Sometimes, it's possible to 
            // get away with six taps, but we need a bit of epsilon value variance here, so there's an extra six.
            float3 getNormal(float3 p, inout float edge, inout float crv) { 
                
                float2 e = float2(.01, 0); // Larger epsilon for greater sample spread, thus thicker edges.
            
                // Take some distance function measurements from either side of the hit point on all three axes.
                float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
                float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
                float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
                float d = map(p)*2.;	// The hit point itself - Doubled to cut down on calculations. See below.
                 
                // Edges - Take a geometry measurement from either side of the hit point. Average them, then see how
                // much the value differs from the hit point itself. Do this for X, Y and Z directions. Here, the sum
                // is used for the overall difference, but there are other ways. Note that it's mainly sharp surface 
                // curves that register a discernible difference.
                edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
                //edge = max(max(abs(d1 + d2 - d), abs(d3 + d4 - d)), abs(d5 + d6 - d)); // Etc.
                
                // Once you have an edge value, it needs to normalized, and smoothed if possible. How you 
                // do that is up to you. This is what I came up with for now, but I might tweak it later.
                edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
                
                // We may as well use the six measurements to obtain a rough curvature value while we're at it.
                crv = clamp((d1 + d2 + d3 + d4 + d5 + d6 - d*3.)*32. + .6, 0., 1.);
                
                // Redoing the calculations for the normal with a more precise epsilon value.
                e = float2(.0025, 0);
                d1 = map(p + e.xyy), d2 = map(p - e.xyy);
                d3 = map(p + e.yxy), d4 = map(p - e.yxy);
                d5 = map(p + e.yyx), d6 = map(p - e.yyx); 
                
                
                // Return the normal.
                // Standard, normalized gradient mearsurement.
                return normalize(float3(d1 - d2, d3 - d4, d5 - d6));
            }
            
            
            
            // I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
            // Anyway, I like this one. I'm assuming it's based on IQ's original.
            float calculateAO(in float3 p, in float3 n)
            {
                float sca = 2., occ = 0.;
                for(float i=0.; i<5.; i++){
                
                    float hr = .01 + i*.5/4.;        
                    float dd = map(n * hr + p);
                    occ += (hr - dd)*sca;
                    sca *= 0.7;
                }
                return clamp(1.0 - occ, 0., 1.);    
            }
            
            
            /*
            // Surface bump function. Cheap, but with decent visual impact.
            float bumpSurf3D( in float3 p){
                
                float c = heightMap((p.xy + p.z*.025)*6.);
                c = cos(c*6.283*3.);
                //c = sqrt(clamp(c+.5, 0., 1.));
                c = (c*.5 + .5);
                
                return c;
            
            }
            
            // Standard function-based bump mapping function.
            float3 dbF(in float3 p, in float3 nor, float bumpfactor){
                
                const float2 e = float2(0.001, 0);
                float ref = bumpSurf3D(p);                 
                float3 grad = (float3(bumpSurf3D(p - e.xyy),
                                  bumpSurf3D(p - e.yxy),
                                  bumpSurf3D(p - e.yyx) )-ref)/e.x;                     
                      
                grad -= nor*dot(nor, grad);          
                                  
                return normalize( nor + grad*bumpfactor );
                
            }
            */
            
            // Compact, self-contained version of IQ's 3D value noise function.
            float n3D(float3 p){
                
                const float3 s = float3(7, 157, 113);
                float3 ip = floor(p); p -= ip; 
                float4 h = float4(0., s.yz, s.y + s.z) + dot(ip, s);
                p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
                h = lerp(frac(sin(h)*43758.5453), frac(sin(h + s.x)*43758.5453), p.x);
                h.xy = lerp(h.xz, h.yw, p.y);
                return lerp(h.x, h.y, p.z); // Range: [0, 1].
            }
            
            // Simple environment mapping. Pass the reflected floattor in and create some
            // colored noise with it. The normal is redundant here, but it can be used
            // to pass into a 3D texture mapping function to produce some interesting
            // environmental reflections.
            float3 envMap(float3 rd, float3 sn){
                
                float3 sRd = rd; // Save rd, just for some lerping at the end.
                
                // Add a time component, scale, then pass into the noise function.
                rd.xy -= _Time.y*.25;
                rd *= 3.;
                
                float c = n3D(rd)*.57 + n3D(rd*2.)*.28 + n3D(rd*4.)*.15; // Noise value.
                c = smoothstep(0.4, 1., c); // Darken and add contast for more of a spotlight look.
                
                float3 col = float3(c, c*c, c*c*c*c); // Simple, warm coloring.
                //float3 col = float3(min(c*1.5, 1.), pow(c, 2.5), pow(c, 12.)); // More color.
                
                // lerp in some more red to tone it down and return.
                return lerp(col, col.yzx, sRd*.25+.25); 
                
            }
            
            // float2 to float2 hash.
            float2 hash22(float2 p) { 
            
                // Faster, but doesn't disperse things quite as nicely as other combinations. :)
                float n = sin(dot(p, float2(41, 289)));
                return frac(float2(262144, 32768)*n)*.75 + .25; 
                
                // Animated.
                //p = frac(float2(262144, 32768)*n); 
                //return sin( p*6.2831853 + _Time.y )*.35 + .65; 
                
            }
            
            // 2D 2nd-order Voronoi: Obviously, this is just a rehash of IQ's original. I've tidied
            // up those if-statements. Since there's less writing, it should go faster. That's how 
            // it works, right? :)
            //
            float Voronoi(in float2 p){
                
                float2 g = floor(p), o; p -= g;
                
                float3 d = float3(1., 1., 1.); // 1.4, etc. "d.z" holds the distance comparison value.
                
                for(int y = -1; y <= 1; y++){
                    for(int x = -1; x <= 1; x++){
                        
                        o = float2(x, y);
                        o += hash22(g + o) - p;
                        
                        d.z = dot(o, o); 
                        // More distance metrics.
                        //o = abs(o);
                        //d.z = max(o.x*.8666 + o.y*.5, o.y);// 
                        //d.z = max(o.x, o.y);
                        //d.z = (o.x*.7 + o.y*.7);
                        
                        d.y = max(d.x, min(d.y, d.z));
                        d.x = min(d.x, d.z); 
                                   
                    }
                }
                
                return max(d.y/1.2 - d.x*1., 0.)/1.2;
                //return d.y - d.x; // return 1.-d.x; // etc.
                
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 rd = normalize(float3(_FloatVariable*i.fragCoord.xy - _ScreenParams.xy, _ScreenParams.y));

                float tm = _Time.y/2.;
                // Rotate the XY-plane back and forth. Note that sine and cosine are kind of rolled into one.
                float2 a = sin(float2(1.570796, 0) + sin(tm/4.)*.3); // Fabrice's observation.
                rd.xy = mul(float2x2(a.x, -a.y, a.y, a.x), rd.xy);
                
                
                // Ray origin. Moving in the X-direction to the right.
                float3 ro = float3(tm, cos(tm/4.), 0.);
                
                
                // Light position, hovering around behind the camera.
                float3 lp = ro + float3(cos(tm/2.)*.5, sin(tm/2.)*.5, -.5);
                
                // Standard raymarching segment. Because of the straight forward setup, not many iterations are necessary.
                float d, t=0.;
                for(int j=0;j<32;j++){
                
                    d = map(ro + rd*t); // distance to the function.
                    t += d*.7; // Total distance from the camera to the surface.
                    
                    // The plane "is" the far plane, so no far=plane break is needed.
                    if(d<0.001) break; 
                
                }
                
                // Edge and curve value. Passed into, and set, during the normal calculation.
                float edge, crv;
            
                // Surface postion, surface normal and light direction.
                float3 sp = ro + rd*t;
                float3 sn = getNormal(sp, edge, crv);
                float3 ld = lp - sp;
                
                
                
                // Coloring and texturing the surface.
                //
                // Height map.
                float c = heightMap(sp.xy); 
                
                // Folding, or wrapping, the values above to produce the snake-like pattern that lines up with the randomly
                // flipped hex cells produced by the height map.
                float3 fold = cos(float3(1, 2, 4)*c*6.283);
                
                // Using the height map value, then wrapping it, to produce a finer grain Truchet pattern for the overlay.
                float c2 = heightMap((sp.xy + sp.z*.025)*6.);
                c2 = cos(c2*6.283*3.);
                c2 = (clamp(c2+.5, 0., 1.)); 

                
                // Function based bump mapping. I prefer none in this example, but it's there if you want it.   
                //if(temp.x>0. || temp.y>0.) sn = dbF(sp, sn, .001);
                
                // Surface color value.
                float3 oC = float3(1., 1., 1.);

                if(fold.x>0.) oC = float3(1, .05, .1)*c2; // Reddish pink with finer grained Truchet overlay.
                
                if(fold.x<0.05 && (fold.y)<0.) oC = float3(1, .7, .45)*(c2*.25 + .75); // Lighter lined borders.
                else if(fold.x<0.) oC = float3(1, .8, .4)*c2; // Gold, with overlay.
                    
                //oC *= n3D(sp*128.)*.35 + .65; // Extra fine grained noisy texturing.

                
                // Sending some greenish particle pulses through the snake-like patterns. With all the shininess going 
                // on, this effect is a little on the subtle side.
                float p1 = 1.0 - smoothstep(0., .1, fold.x*.5+.5); // Restrict to the snake-like path.
                // Other path.
                //float p2 = 1.0 - smoothstep(0., .1, cos(heightMap(sp.xy + 1. + _Time.y/4.)*6.283)*.5+.5);
                float p2 = 1.0 - smoothstep(0., .1, Voronoi(sp.xy*4. + float2(tm, cos(tm/4.))));
                p1 = (p2 + .25)*p1; // Overlap the paths.
                oC += oC.yxz*p1*p1; // Gives a kind of electron effect. Works better with just Voronoi, but it'll do.
                
            
                
                
                float lDist = max(length(ld), 0.001); // Light distance.
                float atten = 1./(1. + lDist*.125); // Light attenuation.
                
                ld /= lDist; // Normalizing the light direction floattor.
                
                float diff = max(dot(ld, sn), 0.); // Diffuse.
                float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 16.); // Specular.
                float fre = pow(clamp(dot(sn, rd) + 1., .0, 1.), 3.); // Fresnel, for some mild glow.
                
                // Shading. Note, there are no actual shadows. The camera is front on, so the following
                // two functions are enough to give a shadowy appearance.
                crv = crv*.9 + .1; // Curvature value, to darken the crevices.
                float ao = calculateAO(sp, sn); // Ambient occlusion, for self shadowing.

            
                
                // Combining the terms above to light the texel.
                float3 col = oC*(diff + .5) + float3(1., .7, .4)*spec*2. + float3(.4, .7, 1)*fre;
                
                col += (oC*.5+.5)*envMap(reflect(rd, sn), sn)*6.; // Fake environment mapping.
            
                
                // Edges.
                col *= 1. - edge*.85; // Darker edges.   
                
                // Applying the shades.
                col *= (atten*crv*ao);


                // Rough gamma correction, then present to the screen.
                return float4(sqrt(clamp(col, 0., 1.)), 1.);
            }

            ENDCG
        }
    }
}
