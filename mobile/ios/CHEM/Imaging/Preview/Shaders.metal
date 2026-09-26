#include <metal_stdlib>
using namespace metal;

struct PreviewVertex {
  float2 position;
  float2 textureCoordinate;
};

struct PreviewUniforms {
  float2 viewSize;
  float2 sourceSize;
  uint orientation;
  uint ycbcrMatrix;
  uint ycbcrRange;
  uint padding;
};

struct PreviewVertexOut {
  float4 position [[position]];
  float2 textureCoordinate;
};

vertex PreviewVertexOut chemPreviewVertex(
  const device PreviewVertex *vertices [[buffer(0)]],
  constant PreviewUniforms &uniforms [[buffer(1)]],
  uint vertexID [[vertex_id]]) {
  PreviewVertexOut out;
  out.position = float4(vertices[vertexID].position, 0.0, 1.0);

  float2 uv = vertices[vertexID].textureCoordinate;
  bool portrait = uniforms.orientation == 1 || uniforms.orientation == 2;
  float2 orientedSize = portrait ? uniforms.sourceSize.yx : uniforms.sourceSize;
  float sourceAspect = orientedSize.x / max(orientedSize.y, 1.0);
  float viewAspect = uniforms.viewSize.x / max(uniforms.viewSize.y, 1.0);

  if (sourceAspect > viewAspect) {
    float visibleWidth = viewAspect / sourceAspect;
    uv.x = (uv.x - 0.5) * visibleWidth + 0.5;
  } else {
    float visibleHeight = sourceAspect / viewAspect;
    uv.y = (uv.y - 0.5) * visibleHeight + 0.5;
  }

  if (uniforms.orientation == 1) {
    out.textureCoordinate = float2(uv.y, 1.0 - uv.x);
  } else if (uniforms.orientation == 2) {
    out.textureCoordinate = float2(1.0 - uv.y, uv.x);
  } else if (uniforms.orientation == 3) {
    out.textureCoordinate = float2(1.0 - uv.x, 1.0 - uv.y);
  } else {
    out.textureCoordinate = uv;
  }
  return out;
}

fragment float4 chemPreviewFragment(
  PreviewVertexOut in [[stage_in]],
  constant PreviewUniforms &uniforms [[buffer(0)]],
  texture2d<float> lumaTexture [[texture(0)]],
  texture2d<float> chromaTexture [[texture(1)]]) {
  constexpr sampler videoSampler(coord::normalized, address::clamp_to_edge, filter::linear);
  float y = lumaTexture.sample(videoSampler, in.textureCoordinate).r;
  float2 cbcr = chromaTexture.sample(videoSampler, in.textureCoordinate).rg;

  float luma;
  float cb;
  float cr;
  if (uniforms.ycbcrRange == 1) {
    luma = y;
    cb = cbcr.x - 0.5;
    cr = cbcr.y - 0.5;
  } else {
    luma = (y - (16.0 / 255.0)) * (255.0 / 219.0);
    cb = (cbcr.x - (128.0 / 255.0)) * (255.0 / 224.0);
    cr = (cbcr.y - (128.0 / 255.0)) * (255.0 / 224.0);
  }
  float3 rgb;
  if (uniforms.ycbcrMatrix == 1) {
    rgb = float3(
      luma + 1.4020 * cr,
      luma - 0.3441 * cb - 0.7141 * cr,
      luma + 1.7720 * cb
    );
  } else {
    rgb = float3(
      luma + 1.5748 * cr,
      luma - 0.1873 * cb - 0.4681 * cr,
      luma + 1.8556 * cb
    );
  }
  return float4(clamp(rgb, 0.0, 1.0), 1.0);
}
