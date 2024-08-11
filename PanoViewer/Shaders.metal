#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct Uniforms {
    float yaw;
    float pitch;
    float roll;
    float fov;
    float aspect;
};

// Quaternion helper functions
float4 quaternion_from_axis_angle(float3 axis, float angle) {
    float s = sin(angle * 0.5);
    return float4(axis * s, cos(angle * 0.5));
}

float4 quaternion_multiply(float4 q1, float4 q2) {
    return float4(
        q1.w * q2.xyz + q2.w * q1.xyz + cross(q1.xyz, q2.xyz),
        q1.w * q2.w - dot(q1.xyz, q2.xyz)
    );
}

float3 rotate_vector(float3 v, float4 q) {
    float3 u = q.xyz;
    float s = q.w;
    return 2.0 * dot(u, v) * u
        + (s*s - dot(u, u)) * v
        + 2.0 * s * cross(u, v);
}

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              constant Uniforms &uniforms [[buffer(1)]]) {
    float2 positions[] = {
        {-1, -1}, {1, -1}, {-1, 1},
        {1, -1}, {1, 1}, {-1, 1}
    };
    
    VertexOut out;
    out.position = float4(positions[vertexID], 0, 1);
    out.texCoord = (positions[vertexID] + 1.0) * 0.5;
    
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> equirectangularTexture [[texture(0)]],
                               constant Uniforms &uniforms [[buffer(0)]]) {
    float2 texCoord = in.texCoord;
    
    // Calculate the horizontal and vertical field of view
    float hfov = uniforms.fov * M_PI_F / 180.0;
    float vfov = 2.0 * atan(tan(hfov * 0.5) / uniforms.aspect);
    
    // Calculate the direction vector
    float3 direction;
    direction.x = (texCoord.x * 2.0 - 1.0) * tan(hfov * 0.5);
    direction.y = (texCoord.y * 2.0 - 1.0) * tan(vfov * 0.5);
    direction.z = -1.0;
    
    // Create quaternions for each rotation
    float4 q_yaw = quaternion_from_axis_angle(float3(0, 1, 0), uniforms.yaw);
    float4 q_pitch = quaternion_from_axis_angle(float3(1, 0, 0), uniforms.pitch);
    float4 q_roll = quaternion_from_axis_angle(float3(0, 0, 1), uniforms.roll);
    
    // Combine rotations
    float4 rotation = quaternion_multiply(q_yaw, quaternion_multiply(q_pitch, q_roll));
    
    // Apply rotation to direction vector
    direction = rotate_vector(direction, rotation);
    
    // Convert to spherical coordinates
    float theta = atan2(direction.x, -direction.z);
    float phi = acos(direction.y / length(direction));
    
    // Map to equirectangular texture coordinates
    float2 equirectangularCoord = float2(
        (theta + M_PI_F) / (2.0 * M_PI_F),
        phi / M_PI_F
    );
    
    constexpr sampler textureSampler(filter::linear, address::repeat);
    return equirectangularTexture.sample(textureSampler, equirectangularCoord);
}
