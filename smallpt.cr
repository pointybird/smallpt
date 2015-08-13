class Vec
  getter :x, :y, :z
  def initialize(@x = 0, @y = 0, @z = 0); end
  def +(b); Vec.new(@x + b.x, @y + b.y, @z + b.z); end
  def -(b); Vec.new(@x - b.x, @y - b.y, @z - b.z); end
  def *(b); Vec.new(@x * b, @y * b, @z * b); end
  def mult(b); Vec.new(@x * b.x, @y * b.y, @z * b.z); end
  def norm; self * (1 / Math.sqrt(@x * @x + @y * @y + @z * @z)); end
  def dot(b); @x * b.x + @y * b.y + @z * b.z; end
  def %(b); Vec.new(@y * b.z - @z * b.y, @z * b.x - @x * b.z, @x * b.y - @y * b.x); end
end

class Ray; getter :o, :d; def initialize(@o, @d); end; end

class Sphere
  getter :rad, :p, :e, :c, :refl
  def initialize(@rad, @p, @e, @c, @refl); end
  def intersect(r) # returns distance, 0 if nohit
    op = @p - r.o # Solve t^2*d.d + 2*t*(o-p).d + (o-p).(o-p)-R^2 = 0 
    eps = 1e-4; b = op.dot(r.d); det = b * b - op.dot(op) + @rad * @rad
    if det < 0 return 0 else det = Math.sqrt(det) end
    (t = b - det) > eps ? t : ((t = b + det) > eps ? t : 0)
  end
end

$spheres = [ # Scene: radius, position, emission, color, material 
  Sphere.new(1e5, Vec.new( 1e5 + 1, 40.8, 81.6), Vec.new,Vec.new(0.75, 0.25, 0.25),:diff),#Left 
  Sphere.new(1e5, Vec.new(-1e5 + 99, 40.8, 81.6),Vec.new,Vec.new(0.25, 0.25, 0.75),:diff),#Rght 
  Sphere.new(1e5, Vec.new(50, 40.8, 1e5), Vec.new,Vec.new(0.75, 0.75, 0.75), :diff),#Back 
  Sphere.new(1e5, Vec.new(50, 40.8, -1e5 + 170), Vec.new, Vec.new, :diff),#Frnt 
  Sphere.new(1e5, Vec.new(50, 1e5, 81.6), Vec.new, Vec.new(0.75, 0.75, 0.75), :diff),#Botm 
  Sphere.new(1e5, Vec.new(50, -1e5 + 81.6, 81.6), Vec.new,Vec.new(0.75, 0.75, 0.75), :diff),#Top 
  Sphere.new(16.5, Vec.new(27, 16.5, 47), Vec.new,Vec.new(1, 1, 1) * 0.999, :spec),#Mirr 
  Sphere.new(16.5, Vec.new(73, 16.5, 78), Vec.new,Vec.new(1, 1, 1) * 0.999, :refr),#Glas 
  Sphere.new(600, Vec.new(50, 681.6 - 0.27, 81.6), Vec.new(12, 12, 12),  Vec.new, :diff) #Lite 
]

def clamp(x); x < 0 ? 0 : x > 1 ? 1 : x; end
def to_int(x); ((clamp(x) ** (1 / 2.2)) * 255 + 0.5).to_i; end
def intersect(r)
  n = $spheres.size; inf = 1e20; id = 0; t = inf
  (n - 1).downto(0).each { |i| d = $spheres[i].intersect(r); t, id = d, i if d != 0 && d < t; }
  {t < inf, t, id}
end

def radiance(r, depth)
  hit, t, id = intersect(r) # t = distance to intersection, id = id of intersected object
  return Vec.new if !hit # if miss, return black 
  obj = $spheres[id] 
  x = r.o + r.d * t; n = (x - obj.p).norm; nl = n.dot(r.d) < 0 ? n : n * -1; f = obj.c
  p = f.x > f.y && f.x > f.z ? f.x : f.y > f.z ? f.y : f.z; # max refl 
  depth += 1
  if depth > 5 if ($random.rand < p) f = f * (1 / p) else return obj.e end end
  if obj.refl == :diff # Ideal DIFFUSE reflection 
    r1 = 2 * Math::PI * $random.rand; r2 = $random.rand; r2s = Math.sqrt(r2)
    w = nl; u = (w.x.abs > 0.1 ? Vec.new(0, 1) : Vec.new(1)).norm; v = w % u
    d = (u * Math.cos(r1) * r2s + v * Math.sin(r1) * r2s + w * Math.sqrt(1 - r2)).norm
    return obj.e + f.mult(radiance(Ray.new(x, d), depth))
  elsif obj.refl == :spec # Ideal SPECULAR reflection 
    return obj.e + f.mult(radiance(Ray.new(x, r.d - n * 2 *n.dot(r.d)), depth))
  end
  refl_ray = Ray.new(x, r.d - n * 2 * n.dot(r.d)) # Ideal dielectric REFRACTION
  into = n.dot(nl) > 0 # Ray from outside going in? 
  nc = 1; nt = 1.5; nnt = into ? nc / nt : nt / nc; ddn = r.d.dot(nl)
  return obj.e + f.mult(radiance(refl_ray, depth)) if (cos2t = 1 - nnt * nnt * (1 - ddn * ddn)) < 0 # Total internal reflection
  tdir = (r.d*nnt - n*((into ? 1 : -1)*(ddn*nnt+Math.sqrt(cos2t)))).norm  
  a = nt - nc; b = nt + nc; r0 = a * a / (b * b); c = 1 - (into ? -ddn : tdir.dot(n))
  re = r0 + (1 - r0) * c * c * c * c * c; tr = 1 - re; p = 0.25 + 0.5 * re; rp = re / p; tp = tr / (1 - p)
  obj.e + f.mult(depth > 2 ? ($random.rand < p ? radiance(refl_ray, depth) * rp : radiance(Ray.new(x, tdir), depth) * tp) : radiance(refl_ray,depth) * re + radiance(Ray.new(x,tdir), depth) * tr)
end

w = 1024; h = 768; samps = ARGV.size == 1 ? (ARGV[0].to_i / 4) : 1 # samples
cam = Ray.new(Vec.new(50, 52, 295.6), Vec.new(0, -0.042612, -1).norm()) # cam pos, dir 
cx = Vec.new(w * 0.5135 / h); cy = (cx % cam.d).norm * 0.5135; c = Array(Vec).new(w * h, Vec.new)
h.times do |y| # Loop over image rows
  print! %{\rRendering (#{samps * 4} spp) #{sprintf("%5.2f", 100.0 * y / (h - 1))}%}
  $random = Random.new(y * y * y)
  w.times do |x|
    i = (h - y - 1) * w + x
    2.times do |sy| # 2x2 subpixel rows 
      2.times do |sx| # 2x2 subpixel cols
        r = Vec.new
        samps.times do
          r1 = 2 * $random.rand; dx = r1 < 1 ? Math.sqrt(r1) - 1 : 1 - Math.sqrt(2 - r1)
          r2 = 2 * $random.rand; dy = r2 < 1 ? Math.sqrt(r2) - 1 : 1 - Math.sqrt(2 - r2)
          d = cx * (((sx + 0.5 + dx) / 2 + x) / w - 0.5) + cy * (((sy + 0.5 + dy) / 2 + y) / h - 0.5) + cam.d
          r = r + radiance(Ray.new(cam.o + (d * 140), d.norm), 0) * (1.0 / samps)
        end # Camera rays are pushed ^^^^^ forward to start in interior
        c[i] = c[i] + Vec.new(clamp(r.x), clamp(r.y), clamp(r.z)) * 0.25
      end
    end
  end
end
File.open("image.ppm", "w") do |f| # Write image to PPM file.
  f.print "P3\n#{w} #{h}\n255\n"
  (w * h).times do |i|
    f.print "#{to_int(c[i].x)} #{to_int(c[i].y)} #{to_int(c[i].z)} "
  end
end
