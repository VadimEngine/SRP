glsl ray trace compute shader

```
#version 430

layout (local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
layout (rgba32f, binding = 0) uniform image2D img;

// Hardcoded camera and sphere
const vec3 cameraPos = vec3(0.0, 0.0, 0.0);
const vec3 sphereCenter = vec3(0.0, 0.0, 3.0);
const float sphereRadius = 1.0;

// Ray-Sphere Intersection Function
bool intersectSphere(vec3 rayOrigin, vec3 rayDir, out float t) {
    vec3 oc = rayOrigin - sphereCenter;
    float a = dot(rayDir, rayDir);
    float b = 2.0 * dot(oc, rayDir);
    float c = dot(oc, oc) - sphereRadius * sphereRadius;
    float discriminant = b * b - 4.0 * a * c;

    if (discriminant < 0.0) {
        return false; // No intersection
    }

    // Find the nearest positive intersection
    float sqrtD = sqrt(discriminant);
    float t0 = (-b - sqrtD) / (2.0 * a);
    float t1 = (-b + sqrtD) / (2.0 * a);
    
    t = (t0 > 0.0) ? t0 : t1;
    return t > 0.0;
}

void main() {
    ivec2 pixelCoords = ivec2(gl_GlobalInvocationID.xy);
    ivec2 imgSize = imageSize(img);
    
    if (pixelCoords.x >= imgSize.x || pixelCoords.y >= imgSize.y) return;

    // Convert pixel coordinates to normalized device coordinates (-1 to 1)
    vec2 uv = (vec2(pixelCoords) / vec2(imgSize)) * 2.0 - 1.0;
    uv.x *= float(imgSize.x) / float(imgSize.y); // Maintain aspect ratio

    // Generate ray direction (assume FOV is ~90 degrees)
    vec3 rayDir = normalize(vec3(uv, 1.0));

    float t;
    if (!intersectSphere(cameraPos, rayDir, t)) {
        return; // No intersection, keep previous framebuffer value
    }

    // Compute intersection point
    vec3 hitPoint = cameraPos + t * rayDir;

    // Compute normal at hit point
    vec3 normal = normalize(hitPoint - sphereCenter);

    // Simple lighting (light at (1,1,0))
    vec3 lightDir = normalize(vec3(1.0, 1.0, 0.0));
    float brightness = max(dot(normal, lightDir), 0.0);

    // Shaded color
    vec4 newColor = vec4(vec3(1.0, 0.2, 0.2) * brightness, 1.0); // Red sphere with shading

    imageStore(img, pixelCoords, newColor);
}
```
