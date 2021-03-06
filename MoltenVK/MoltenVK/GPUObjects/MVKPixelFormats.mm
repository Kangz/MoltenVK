/*
 * MVKPixelFormats.mm
 *
 * Copyright (c) 2015-2020 The Brenwill Workshop Ltd. (http://www.brenwill.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "mvk_datatypes.hpp"
#include "MVKPixelFormats.h"
#include "MVKVulkanAPIObject.h"
#include "MVKFoundation.h"
#include "MVKLogging.h"
#include <string>
#include <limits>

using namespace std;


#pragma mark -
#pragma mark Image properties

#define MVK_FMT_IMAGE_FEATS			(VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT                    \
									| VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT                   \
                                    | VK_FORMAT_FEATURE_BLIT_SRC_BIT                        \
									| VK_FORMAT_FEATURE_TRANSFER_SRC_BIT                    \
									| VK_FORMAT_FEATURE_TRANSFER_DST_BIT)

#define MVK_FMT_COLOR_INTEGER_FEATS	(MVK_FMT_IMAGE_FEATS                                    \
									| VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT                \
									| VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BLEND_BIT          \
                                    | VK_FORMAT_FEATURE_BLIT_DST_BIT)

#define MVK_FMT_COLOR_FEATS			(MVK_FMT_COLOR_INTEGER_FEATS | VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT)

#if MVK_IOS
// iOS does not support filtering of float32 values.
#	define MVK_FMT_COLOR_FLOAT32_FEATS	MVK_FMT_COLOR_INTEGER_FEATS
#else
#	define MVK_FMT_COLOR_FLOAT32_FEATS	MVK_FMT_COLOR_FEATS
#endif

#define MVK_FMT_STENCIL_FEATS		(MVK_FMT_IMAGE_FEATS | VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT)

#if MVK_IOS
// iOS does not support filtering of depth values.
#	define MVK_FMT_DEPTH_FEATS		MVK_FMT_STENCIL_FEATS
#else
#	define MVK_FMT_DEPTH_FEATS		(MVK_FMT_STENCIL_FEATS | VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT)
#endif

#define MVK_FMT_COMPRESSED_FEATS	(VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT                    \
									| VK_FORMAT_FEATURE_TRANSFER_SRC_BIT                    \
									| VK_FORMAT_FEATURE_TRANSFER_DST_BIT                    \
									| VK_FORMAT_FEATURE_BLIT_SRC_BIT                        \
									| VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT)

#if MVK_MACOS
// macOS does not support linear images as framebuffer attachments.
#define MVK_FMT_LINEAR_TILING_FEATS	(MVK_FMT_IMAGE_FEATS | VK_FORMAT_FEATURE_SAMPLED_IMAGE_FILTER_LINEAR_BIT)

// macOS also does not support E5B9G9R9 for anything but filtering.
#define MVK_FMT_E5B9G9R9_FEATS 		MVK_FMT_COMPRESSED_FEATS
#else
#define MVK_FMT_LINEAR_TILING_FEATS	MVK_FMT_COLOR_FEATS
#define MVK_FMT_E5B9G9R9_FEATS		MVK_FMT_COLOR_FEATS
#endif

#define MVK_FMT_BUFFER_FEATS		(VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT             \
									| VK_FORMAT_FEATURE_STORAGE_TEXEL_BUFFER_BIT)

#define MVK_FMT_BUFFER_VTX_FEATS	(MVK_FMT_BUFFER_FEATS | VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT)

#define MVK_FMT_BUFFER_RDONLY_FEATS	(VK_FORMAT_FEATURE_UNIFORM_TEXEL_BUFFER_BIT)

#if MVK_MACOS
#define MVK_FMT_E5B9G9R9_BUFFER_FEATS 		MVK_FMT_BUFFER_RDONLY_FEATS
#else
#define MVK_FMT_E5B9G9R9_BUFFER_FEATS 		MVK_FMT_BUFFER_FEATS
#endif

#define MVK_FMT_NO_FEATS			0


// Add stub defs for unsupported MTLPixelFormats per platform
#if MVK_MACOS
#   define MTLPixelFormatABGR4Unorm             MTLPixelFormatInvalid
#   define MTLPixelFormatB5G6R5Unorm            MTLPixelFormatInvalid
#   define MTLPixelFormatA1BGR5Unorm            MTLPixelFormatInvalid
#   define MTLPixelFormatBGR5A1Unorm            MTLPixelFormatInvalid
#   define MTLPixelFormatR8Unorm_sRGB           MTLPixelFormatInvalid
#   define MTLPixelFormatRG8Unorm_sRGB          MTLPixelFormatInvalid

#   define MTLPixelFormatETC2_RGB8              MTLPixelFormatInvalid
#   define MTLPixelFormatETC2_RGB8_sRGB         MTLPixelFormatInvalid
#   define MTLPixelFormatETC2_RGB8A1            MTLPixelFormatInvalid
#   define MTLPixelFormatETC2_RGB8A1_sRGB       MTLPixelFormatInvalid
#   define MTLPixelFormatEAC_RGBA8              MTLPixelFormatInvalid
#   define MTLPixelFormatEAC_RGBA8_sRGB         MTLPixelFormatInvalid
#   define MTLPixelFormatEAC_R11Unorm           MTLPixelFormatInvalid
#   define MTLPixelFormatEAC_R11Snorm           MTLPixelFormatInvalid
#   define MTLPixelFormatEAC_RG11Unorm          MTLPixelFormatInvalid
#   define MTLPixelFormatEAC_RG11Snorm          MTLPixelFormatInvalid

#   define MTLPixelFormatASTC_4x4_LDR           MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_4x4_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_5x4_LDR           MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_5x4_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_5x5_LDR           MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_5x5_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_6x5_LDR           MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_6x5_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_6x6_LDR           MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_6x6_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_8x5_LDR           MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_8x5_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_8x6_LDR           MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_8x6_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_8x8_LDR           MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_8x8_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_10x5_LDR          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_10x5_sRGB         MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_10x6_LDR          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_10x6_sRGB         MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_10x8_LDR          MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_10x8_sRGB         MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_10x10_LDR         MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_10x10_sRGB        MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_12x10_LDR         MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_12x10_sRGB        MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_12x12_LDR         MTLPixelFormatInvalid
#   define MTLPixelFormatASTC_12x12_sRGB        MTLPixelFormatInvalid

#   define MTLPixelFormatPVRTC_RGB_2BPP         MTLPixelFormatInvalid
#   define MTLPixelFormatPVRTC_RGB_2BPP_sRGB    MTLPixelFormatInvalid
#   define MTLPixelFormatPVRTC_RGB_4BPP         MTLPixelFormatInvalid
#   define MTLPixelFormatPVRTC_RGB_4BPP_sRGB    MTLPixelFormatInvalid
#   define MTLPixelFormatPVRTC_RGBA_2BPP        MTLPixelFormatInvalid
#   define MTLPixelFormatPVRTC_RGBA_2BPP_sRGB   MTLPixelFormatInvalid
#   define MTLPixelFormatPVRTC_RGBA_4BPP        MTLPixelFormatInvalid
#   define MTLPixelFormatPVRTC_RGBA_4BPP_sRGB   MTLPixelFormatInvalid

#   define MTLPixelFormatDepth16Unorm_Stencil8  MTLPixelFormatDepth24Unorm_Stencil8
#endif

#if MVK_IOS
#   define MTLPixelFormatDepth16Unorm           MTLPixelFormatInvalid
#   define MTLPixelFormatDepth24Unorm_Stencil8  MTLPixelFormatInvalid
#   define MTLPixelFormatBC1_RGBA               MTLPixelFormatInvalid
#   define MTLPixelFormatBC1_RGBA_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatBC2_RGBA               MTLPixelFormatInvalid
#   define MTLPixelFormatBC2_RGBA_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatBC3_RGBA               MTLPixelFormatInvalid
#   define MTLPixelFormatBC3_RGBA_sRGB          MTLPixelFormatInvalid
#   define MTLPixelFormatBC4_RUnorm             MTLPixelFormatInvalid
#   define MTLPixelFormatBC4_RSnorm             MTLPixelFormatInvalid
#   define MTLPixelFormatBC5_RGUnorm            MTLPixelFormatInvalid
#   define MTLPixelFormatBC5_RGSnorm            MTLPixelFormatInvalid
#   define MTLPixelFormatBC6H_RGBUfloat         MTLPixelFormatInvalid
#   define MTLPixelFormatBC6H_RGBFloat          MTLPixelFormatInvalid
#   define MTLPixelFormatBC7_RGBAUnorm          MTLPixelFormatInvalid
#   define MTLPixelFormatBC7_RGBAUnorm_sRGB     MTLPixelFormatInvalid

#   define MTLPixelFormatDepth16Unorm_Stencil8  MTLPixelFormatDepth32Float_Stencil8
#endif


#pragma mark -
#pragma mark MVKPixelFormats

bool MVKPixelFormats::vkFormatIsSupported(VkFormat vkFormat) {
	return getVkFormatDesc(vkFormat).isSupported();
}

bool MVKPixelFormats::mtlPixelFormatIsSupported(MTLPixelFormat mtlFormat) {
	return getMTLPixelFormatDesc(mtlFormat).isSupported();
}

bool MVKPixelFormats::mtlPixelFormatIsDepthFormat(MTLPixelFormat mtlFormat) {
	switch (mtlFormat) {
		case MTLPixelFormatDepth32Float:
#if MVK_MACOS
		case MTLPixelFormatDepth16Unorm:
		case MTLPixelFormatDepth24Unorm_Stencil8:
#endif
		case MTLPixelFormatDepth32Float_Stencil8:
			return true;
		default:
			return false;
	}
}

bool MVKPixelFormats::mtlPixelFormatIsStencilFormat(MTLPixelFormat mtlFormat) {
	switch (mtlFormat) {
		case MTLPixelFormatStencil8:
#if MVK_MACOS
		case MTLPixelFormatDepth24Unorm_Stencil8:
		case MTLPixelFormatX24_Stencil8:
#endif
		case MTLPixelFormatDepth32Float_Stencil8:
		case MTLPixelFormatX32_Stencil8:
			return true;
		default:
			return false;
	}
}

bool MVKPixelFormats::mtlPixelFormatIsPVRTCFormat(MTLPixelFormat mtlFormat) {
	switch (mtlFormat) {
#if MVK_IOS
		case MTLPixelFormatPVRTC_RGBA_2BPP:
		case MTLPixelFormatPVRTC_RGBA_2BPP_sRGB:
		case MTLPixelFormatPVRTC_RGBA_4BPP:
		case MTLPixelFormatPVRTC_RGBA_4BPP_sRGB:
		case MTLPixelFormatPVRTC_RGB_2BPP:
		case MTLPixelFormatPVRTC_RGB_2BPP_sRGB:
		case MTLPixelFormatPVRTC_RGB_4BPP:
		case MTLPixelFormatPVRTC_RGB_4BPP_sRGB:
			return true;
#endif
		default:
			return false;
	}
}

MVKFormatType MVKPixelFormats::getFormatTypeFromVkFormat(VkFormat vkFormat) {
	return getVkFormatDesc(vkFormat).formatType;
}

MVKFormatType MVKPixelFormats::getFormatTypeFromMTLPixelFormat(MTLPixelFormat mtlFormat) {
	return getVkFormatDesc(mtlFormat).formatType;
}

MTLPixelFormat MVKPixelFormats::getMTLPixelFormatFromVkFormat(VkFormat vkFormat) {
	MTLPixelFormat mtlPixFmt = MTLPixelFormatInvalid;

	auto& vkDesc = getVkFormatDesc(vkFormat);
	if (vkDesc.isSupported()) {
		mtlPixFmt = vkDesc.mtlPixelFormat;
	} else if (vkFormat != VK_FORMAT_UNDEFINED) {
		// If the MTLPixelFormat is not supported but VkFormat is valid, attempt to substitute a different format.
		mtlPixFmt = vkDesc.mtlPixelFormatSubstitute;

		// Report an error if there is no substitute, or the first time a substitution is made.
		if ( !mtlPixFmt || !vkDesc.hasReportedSubstitution ) {
			string errMsg;
			errMsg += "VkFormat ";
			errMsg += (vkDesc.name) ? vkDesc.name : to_string(vkDesc.vkFormat);
			errMsg += " is not supported on this device.";

			if (mtlPixFmt) {
				vkDesc.hasReportedSubstitution = true;

				auto& vkDescSubs = getVkFormatDesc(mtlPixFmt);
				errMsg += " Using VkFormat ";
				errMsg += (vkDescSubs.name) ? vkDescSubs.name : to_string(vkDescSubs.vkFormat);
				errMsg += " instead.";
			}
			MVKBaseObject::reportError(_apiObject, VK_ERROR_FORMAT_NOT_SUPPORTED, "%s", errMsg.c_str());
		}
	}

	return mtlPixFmt;
}

VkFormat MVKPixelFormats::getVkFormatFromMTLPixelFormat(MTLPixelFormat mtlFormat) {
    return getMTLPixelFormatDesc(mtlFormat).vkFormat;
}

uint32_t MVKPixelFormats::getVkFormatBytesPerBlock(VkFormat vkFormat) {
    return getVkFormatDesc(vkFormat).bytesPerBlock;
}

uint32_t MVKPixelFormats::getMTLPixelFormatBytesPerBlock(MTLPixelFormat mtlFormat) {
    return getVkFormatDesc(mtlFormat).bytesPerBlock;
}

VkExtent2D MVKPixelFormats::getVkFormatBlockTexelSize(VkFormat vkFormat) {
    return getVkFormatDesc(vkFormat).blockTexelSize;
}

VkExtent2D MVKPixelFormats::getMTLPixelFormatBlockTexelSize(MTLPixelFormat mtlFormat) {
    return getVkFormatDesc(mtlFormat).blockTexelSize;
}

float MVKPixelFormats::getVkFormatBytesPerTexel(VkFormat vkFormat) {
    return getVkFormatDesc(vkFormat).bytesPerTexel();
}

float MVKPixelFormats::getMTLPixelFormatBytesPerTexel(MTLPixelFormat mtlFormat) {
    return getVkFormatDesc(mtlFormat).bytesPerTexel();
}

size_t MVKPixelFormats::getVkFormatBytesPerRow(VkFormat vkFormat, uint32_t texelsPerRow) {
    auto& vkDesc = getVkFormatDesc(vkFormat);
    return mvkCeilingDivide(texelsPerRow, vkDesc.blockTexelSize.width) * vkDesc.bytesPerBlock;
}

size_t MVKPixelFormats::getMTLPixelFormatBytesPerRow(MTLPixelFormat mtlFormat, uint32_t texelsPerRow) {
	auto& vkDesc = getVkFormatDesc(mtlFormat);
    return mvkCeilingDivide(texelsPerRow, vkDesc.blockTexelSize.width) * vkDesc.bytesPerBlock;
}

size_t MVKPixelFormats::getVkFormatBytesPerLayer(VkFormat vkFormat, size_t bytesPerRow, uint32_t texelRowsPerLayer) {
    return mvkCeilingDivide(texelRowsPerLayer, getVkFormatDesc(vkFormat).blockTexelSize.height) * bytesPerRow;
}

size_t MVKPixelFormats::getMTLPixelFormatBytesPerLayer(MTLPixelFormat mtlFormat, size_t bytesPerRow, uint32_t texelRowsPerLayer) {
    return mvkCeilingDivide(texelRowsPerLayer, getVkFormatDesc(mtlFormat).blockTexelSize.height) * bytesPerRow;
}

VkFormatProperties MVKPixelFormats::getVkFormatProperties(VkFormat vkFormat) {
	VkFormatProperties fmtProps = {MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS};
	auto& vkDesc = getVkFormatDesc(vkFormat);
	if (vkDesc.isSupported()) {
		fmtProps = vkDesc.properties;
		if ( !vkDesc.vertexIsSupportedOrSubstitutable() ) {
			// If vertex format is not supported, disable vertex buffer bit
			fmtProps.bufferFeatures &= ~VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT;
		}
	} else {
		// If texture format is unsupported, vertex buffer format may still be.
		fmtProps.bufferFeatures |= vkDesc.properties.bufferFeatures & VK_FORMAT_FEATURE_VERTEX_BUFFER_BIT;
	}
	return fmtProps;
}

const char* MVKPixelFormats::getVkFormatName(VkFormat vkFormat) {
    return getVkFormatDesc(vkFormat).name;
}

const char* MVKPixelFormats::getMTLPixelFormatName(MTLPixelFormat mtlFormat) {
    return getMTLPixelFormatDesc(mtlFormat).name;
}

void MVKPixelFormats::enumerateSupportedFormats(VkFormatProperties properties, bool any, std::function<bool(VkFormat)> func) {
	static const auto areFeaturesSupported = [any](uint32_t a, uint32_t b) {
		if (b == 0) return true;
		if (any)
			return mvkIsAnyFlagEnabled(a, b);
		else
			return mvkAreAllFlagsEnabled(a, b);
	};
	for (auto& vkDesc : _vkFormatDescriptions) {
		if (vkDesc.isSupported() &&
			areFeaturesSupported(vkDesc.properties.linearTilingFeatures, properties.linearTilingFeatures) &&
			areFeaturesSupported(vkDesc.properties.optimalTilingFeatures, properties.optimalTilingFeatures) &&
			areFeaturesSupported(vkDesc.properties.bufferFeatures, properties.bufferFeatures)) {
			if ( !func(vkDesc.vkFormat) ) {
				break;
			}
		}
	}
}

MTLVertexFormat MVKPixelFormats::getMTLVertexFormatFromVkFormat(VkFormat vkFormat) {
	MTLVertexFormat mtlVtxFmt = MTLVertexFormatInvalid;

	auto& vkDesc = getVkFormatDesc(vkFormat);
	if (vkDesc.vertexIsSupported()) {
		mtlVtxFmt = vkDesc.mtlVertexFormat;
	} else if (vkFormat != VK_FORMAT_UNDEFINED) {
		// If the MTLVertexFormat is not supported but VkFormat is valid,
		// report an error, and possibly substitute a different MTLVertexFormat.
		string errMsg;
		errMsg += "VkFormat ";
		errMsg += (vkDesc.name) ? vkDesc.name : to_string(vkDesc.vkFormat);
		errMsg += " is not supported for vertex buffers on this device.";

		if (vkDesc.vertexIsSupportedOrSubstitutable()) {
			mtlVtxFmt = vkDesc.mtlVertexFormatSubstitute;

			auto& vkDescSubs = getVkFormatDesc(getMTLVertexFormatDesc(mtlVtxFmt).vkFormat);
			errMsg += " Using VkFormat ";
			errMsg += (vkDescSubs.name) ? vkDescSubs.name : to_string(vkDescSubs.vkFormat);
			errMsg += " instead.";
		}
		MVKBaseObject::reportError(_apiObject, VK_ERROR_FORMAT_NOT_SUPPORTED, "%s", errMsg.c_str());
	}

	return mtlVtxFmt;
}

MTLClearColor MVKPixelFormats::getMTLClearColorFromVkClearValue(VkClearValue vkClearValue,
														   VkFormat vkFormat) {
	MTLClearColor mtlClr;
	switch (getFormatTypeFromVkFormat(vkFormat)) {
		case kMVKFormatColorHalf:
		case kMVKFormatColorFloat:
			mtlClr.red		= vkClearValue.color.float32[0];
			mtlClr.green	= vkClearValue.color.float32[1];
			mtlClr.blue		= vkClearValue.color.float32[2];
			mtlClr.alpha	= vkClearValue.color.float32[3];
			break;
		case kMVKFormatColorUInt8:
		case kMVKFormatColorUInt16:
		case kMVKFormatColorUInt32:
			mtlClr.red		= vkClearValue.color.uint32[0];
			mtlClr.green	= vkClearValue.color.uint32[1];
			mtlClr.blue		= vkClearValue.color.uint32[2];
			mtlClr.alpha	= vkClearValue.color.uint32[3];
			break;
		case kMVKFormatColorInt8:
		case kMVKFormatColorInt16:
		case kMVKFormatColorInt32:
			mtlClr.red		= vkClearValue.color.int32[0];
			mtlClr.green	= vkClearValue.color.int32[1];
			mtlClr.blue		= vkClearValue.color.int32[2];
			mtlClr.alpha	= vkClearValue.color.int32[3];
			break;
		default:
			mtlClr.red		= 0.0;
			mtlClr.green	= 0.0;
			mtlClr.blue		= 0.0;
			mtlClr.alpha	= 1.0;
			break;
	}
	return mtlClr;
}

double MVKPixelFormats::getMTLClearDepthFromVkClearValue(VkClearValue vkClearValue) {
	return vkClearValue.depthStencil.depth;
}

uint32_t MVKPixelFormats::getMTLClearStencilFromVkClearValue(VkClearValue vkClearValue) {
	return vkClearValue.depthStencil.stencil;
}

VkImageUsageFlags MVKPixelFormats::getVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsage mtlUsage,
																	  MTLPixelFormat mtlFormat) {
    VkImageUsageFlags vkImageUsageFlags = 0;

    if ( mvkAreAllFlagsEnabled(mtlUsage, MTLTextureUsageShaderRead) ) {
        mvkEnableFlag(vkImageUsageFlags, VK_IMAGE_USAGE_TRANSFER_SRC_BIT);
        mvkEnableFlag(vkImageUsageFlags, VK_IMAGE_USAGE_SAMPLED_BIT);
        mvkEnableFlag(vkImageUsageFlags, VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT);
    }
    if ( mvkAreAllFlagsEnabled(mtlUsage, MTLTextureUsageRenderTarget) ) {
        mvkEnableFlag(vkImageUsageFlags, VK_IMAGE_USAGE_TRANSFER_DST_BIT);
        if (mtlPixelFormatIsDepthFormat(mtlFormat) || mtlPixelFormatIsStencilFormat(mtlFormat)) {
            mvkEnableFlag(vkImageUsageFlags, VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT);
        } else {
            mvkEnableFlag(vkImageUsageFlags, VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT);
        }
    }
    if ( mvkAreAllFlagsEnabled(mtlUsage, MTLTextureUsageShaderWrite) ) {
        mvkEnableFlag(vkImageUsageFlags, VK_IMAGE_USAGE_STORAGE_BIT);
    }

    return vkImageUsageFlags;
}

// Return a reference to the Vulkan format descriptor corresponding to the VkFormat.
MVKVkFormatDesc& MVKPixelFormats::getVkFormatDesc(VkFormat vkFormat) {
	uint16_t fmtIdx = (vkFormat < _vkFormatCoreCount) ? _vkFormatDescIndicesByVkFormatsCore[vkFormat] : _vkFormatDescIndicesByVkFormatsExt[vkFormat];
	return _vkFormatDescriptions[fmtIdx];
}

// Return a reference to the Metal format descriptor corresponding to the MTLPixelFormat.
MVKMTLFormatDesc& MVKPixelFormats::getMTLPixelFormatDesc(MTLPixelFormat mtlFormat) {
	uint16_t fmtIdx = (mtlFormat < _mtlPixelFormatCount) ? _mtlFormatDescIndicesByMTLPixelFormats[mtlFormat] : 0;
	return _mtlPixelFormatDescriptions[fmtIdx];
}

// Return a reference to the Metal format descriptor corresponding to the MTLVertexFormat.
MVKMTLFormatDesc& MVKPixelFormats::getMTLVertexFormatDesc(MTLVertexFormat mtlFormat) {
	uint16_t fmtIdx = (mtlFormat < _mtlVertexFormatCount) ? _mtlFormatDescIndicesByMTLVertexFormats[mtlFormat] : 0;
	return _mtlVertexFormatDescriptions[fmtIdx];
}

// Return a reference to the Vulkan format descriptor corresponding to the MTLPixelFormat.
MVKVkFormatDesc& MVKPixelFormats::getVkFormatDesc(MTLPixelFormat mtlFormat) {
	return getVkFormatDesc(getMTLPixelFormatDesc(mtlFormat).vkFormat);
}


#pragma mark Construction

MVKPixelFormats::MVKPixelFormats(MVKVulkanAPIObject* apiObject, id<MTLDevice> mtlDevice) : _apiObject(apiObject) {
	initVkFormatCapabilities();
	initMTLPixelFormatCapabilities();
	initMTLVertexFormatCapabilities();
	buildFormatMaps();
	modifyFormatCapabilitiesForMTLDevice(mtlDevice);
//	test();
}

static const MVKOSVersion kMTLFmtNA = numeric_limits<MVKOSVersion>::max();

#define MVK_ADD_VKFMT_STRUCT(VK_FMT, MTL_FMT, MTL_FMT_ALT, MTL_VTX_FMT, MTL_VTX_FMT_ALT, BLK_W, BLK_H, BLK_BYTE_CNT, MVK_FMT_TYPE, PIXEL_FEATS, BUFFER_FEATS)  \
	MVKAssert(fmtIdx < _vkFormatCount, "Attempting to describe %d VkFormats, but only have space for %d. Increase the value of _vkFormatCount", fmtIdx + 1, _vkFormatCount);		\
	_vkFormatDescriptions[fmtIdx++] = { VK_FMT, MTL_FMT, MTL_FMT_ALT, MTL_VTX_FMT, MTL_VTX_FMT_ALT, { BLK_W, BLK_H }, BLK_BYTE_CNT, MVK_FMT_TYPE, { (PIXEL_FEATS & MVK_FMT_LINEAR_TILING_FEATS), PIXEL_FEATS, BUFFER_FEATS }, #VK_FMT, false }

void MVKPixelFormats::initVkFormatCapabilities() {

	mvkClear(_vkFormatDescriptions, _vkFormatCount);

	uint32_t fmtIdx = 0;

	// When adding to this list, be sure to ensure _vkFormatCount is large enough for the format count
	// VK_FORMAT_UNDEFINED must come first.
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_UNDEFINED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 0, kMVKFormatNone, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R4G4_UNORM_PACK8, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 1, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R4G4B4A4_UNORM_PACK16, MTLPixelFormatABGR4Unorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );	// Vulkan packed is reversed
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B4G4R4A4_UNORM_PACK16, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R5G6B5_UNORM_PACK16, MTLPixelFormatB5G6R5Unorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );	// Vulkan packed is reversed
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B5G6R5_UNORM_PACK16, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R5G5B5A1_UNORM_PACK16, MTLPixelFormatA1BGR5Unorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );	// Vulkan packed is reversed
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B5G5R5A1_UNORM_PACK16, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A1R5G5B5_UNORM_PACK16, MTLPixelFormatBGR5A1Unorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );	// Vulkan packed is reversed

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8_UNORM, MTLPixelFormatR8Unorm, MTLPixelFormatInvalid, MTLVertexFormatUCharNormalized, MTLVertexFormatUChar2Normalized, 1, 1, 1, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8_SNORM, MTLPixelFormatR8Snorm, MTLPixelFormatInvalid, MTLVertexFormatCharNormalized, MTLVertexFormatChar2Normalized, 1, 1, 1, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 1, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 1, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8_UINT, MTLPixelFormatR8Uint, MTLPixelFormatInvalid, MTLVertexFormatUChar, MTLVertexFormatUChar2, 1, 1, 1, kMVKFormatColorUInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8_SINT, MTLPixelFormatR8Sint, MTLPixelFormatInvalid, MTLVertexFormatChar, MTLVertexFormatChar2, 1, 1, 1, kMVKFormatColorInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8_SRGB, MTLPixelFormatR8Unorm_sRGB, MTLPixelFormatInvalid, MTLVertexFormatUCharNormalized, MTLVertexFormatUChar2Normalized, 1, 1, 1, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8_UNORM, MTLPixelFormatRG8Unorm, MTLPixelFormatInvalid, MTLVertexFormatUChar2Normalized, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8_SNORM, MTLPixelFormatRG8Snorm, MTLPixelFormatInvalid, MTLVertexFormatChar2Normalized, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8_UINT, MTLPixelFormatRG8Uint, MTLPixelFormatInvalid, MTLVertexFormatUChar2, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorUInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8_SINT, MTLPixelFormatRG8Sint, MTLPixelFormatInvalid, MTLVertexFormatChar2, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8_SRGB, MTLPixelFormatRG8Unorm_sRGB, MTLPixelFormatInvalid, MTLVertexFormatUChar2Normalized, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8_UNORM, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatUChar3Normalized, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8_SNORM, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatChar3Normalized, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8_UINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatUChar3, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorUInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8_SINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatChar3, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8_SRGB, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatUChar3Normalized, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8_UNORM, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8_SNORM, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8_UINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorUInt8, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8_SINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorInt8, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8_SRGB, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8A8_UNORM, MTLPixelFormatRGBA8Unorm, MTLPixelFormatInvalid, MTLVertexFormatUChar4Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8A8_SNORM, MTLPixelFormatRGBA8Snorm, MTLPixelFormatInvalid, MTLVertexFormatChar4Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8A8_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8A8_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8A8_UINT, MTLPixelFormatRGBA8Uint, MTLPixelFormatInvalid, MTLVertexFormatUChar4, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorUInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8A8_SINT, MTLPixelFormatRGBA8Sint, MTLPixelFormatInvalid, MTLVertexFormatChar4, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R8G8B8A8_SRGB, MTLPixelFormatRGBA8Unorm_sRGB, MTLPixelFormatInvalid, MTLVertexFormatUChar4Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8A8_UNORM, MTLPixelFormatBGRA8Unorm, MTLPixelFormatInvalid, MTLVertexFormatUChar4Normalized_BGRA, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8A8_SNORM, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8A8_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8A8_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8A8_UINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorUInt8, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8A8_SINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorInt8, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B8G8R8A8_SRGB, MTLPixelFormatBGRA8Unorm_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A8B8G8R8_UNORM_PACK32, MTLPixelFormatRGBA8Unorm, MTLPixelFormatInvalid, MTLVertexFormatUChar4Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A8B8G8R8_SNORM_PACK32, MTLPixelFormatRGBA8Snorm, MTLPixelFormatInvalid, MTLVertexFormatChar4Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A8B8G8R8_USCALED_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A8B8G8R8_SSCALED_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A8B8G8R8_UINT_PACK32, MTLPixelFormatRGBA8Uint, MTLPixelFormatInvalid, MTLVertexFormatUChar4, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorUInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A8B8G8R8_SINT_PACK32, MTLPixelFormatRGBA8Sint, MTLPixelFormatInvalid, MTLVertexFormatChar4, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorInt8, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A8B8G8R8_SRGB_PACK32, MTLPixelFormatRGBA8Unorm_sRGB, MTLPixelFormatInvalid, MTLVertexFormatUChar4Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2R10G10B10_UNORM_PACK32, MTLPixelFormatBGR10A2Unorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );	// Vulkan packed is reversed
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2R10G10B10_SNORM_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2R10G10B10_USCALED_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2R10G10B10_SSCALED_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2R10G10B10_UINT_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorUInt16, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2R10G10B10_SINT_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorInt16, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2B10G10R10_UNORM_PACK32, MTLPixelFormatRGB10A2Unorm, MTLPixelFormatInvalid, MTLVertexFormatUInt1010102Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );	// Vulkan packed is reversed
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2B10G10R10_SNORM_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInt1010102Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2B10G10R10_USCALED_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2B10G10R10_SSCALED_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2B10G10R10_UINT_PACK32, MTLPixelFormatRGB10A2Uint, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorUInt16, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_FEATS );		// Vulkan packed is reversed
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_A2B10G10R10_SINT_PACK32, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorInt16, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16_UNORM, MTLPixelFormatR16Unorm, MTLPixelFormatInvalid, MTLVertexFormatUShortNormalized, MTLVertexFormatUShort2Normalized, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16_SNORM, MTLPixelFormatR16Snorm, MTLPixelFormatInvalid, MTLVertexFormatShortNormalized, MTLVertexFormatShort2Normalized, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16_UINT, MTLPixelFormatR16Uint, MTLPixelFormatInvalid, MTLVertexFormatUShort, MTLVertexFormatUShort2, 1, 1, 2, kMVKFormatColorUInt16, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16_SINT, MTLPixelFormatR16Sint, MTLPixelFormatInvalid, MTLVertexFormatShort, MTLVertexFormatShort2, 1, 1, 2, kMVKFormatColorInt16, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16_SFLOAT, MTLPixelFormatR16Float, MTLPixelFormatInvalid, MTLVertexFormatHalf, MTLVertexFormatHalf2, 1, 1, 2, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16_UNORM, MTLPixelFormatRG16Unorm, MTLPixelFormatInvalid, MTLVertexFormatUShort2Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16_SNORM, MTLPixelFormatRG16Snorm, MTLPixelFormatInvalid, MTLVertexFormatShort2Normalized, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16_UINT, MTLPixelFormatRG16Uint, MTLPixelFormatInvalid, MTLVertexFormatUShort2, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorUInt16, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16_SINT, MTLPixelFormatRG16Sint, MTLPixelFormatInvalid, MTLVertexFormatShort2, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorInt16, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16_SFLOAT, MTLPixelFormatRG16Float, MTLPixelFormatInvalid, MTLVertexFormatHalf2, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16_UNORM, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatUShort3Normalized, MTLVertexFormatInvalid, 1, 1, 6, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16_SNORM, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatShort3Normalized, MTLVertexFormatInvalid, 1, 1, 6, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 6, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 6, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16_UINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatUShort3, MTLVertexFormatInvalid, 1, 1, 6, kMVKFormatColorUInt16, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16_SINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatShort3, MTLVertexFormatInvalid, 1, 1, 6, kMVKFormatColorInt16, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16_SFLOAT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatHalf3, MTLVertexFormatInvalid, 1, 1, 6, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16A16_UNORM, MTLPixelFormatRGBA16Unorm, MTLPixelFormatInvalid, MTLVertexFormatUShort4Normalized, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16A16_SNORM, MTLPixelFormatRGBA16Snorm, MTLPixelFormatInvalid, MTLVertexFormatShort4Normalized, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16A16_USCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16A16_SSCALED, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16A16_UINT, MTLPixelFormatRGBA16Uint, MTLPixelFormatInvalid, MTLVertexFormatUShort4, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorUInt16, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16A16_SINT, MTLPixelFormatRGBA16Sint, MTLPixelFormatInvalid, MTLVertexFormatShort4, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorInt16, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R16G16B16A16_SFLOAT, MTLPixelFormatRGBA16Float, MTLPixelFormatInvalid, MTLVertexFormatHalf4, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_VTX_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32_UINT, MTLPixelFormatR32Uint, MTLPixelFormatInvalid, MTLVertexFormatUInt, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorUInt32, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32_SINT, MTLPixelFormatR32Sint, MTLPixelFormatInvalid, MTLVertexFormatInt, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorInt32, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32_SFLOAT, MTLPixelFormatR32Float, MTLPixelFormatInvalid, MTLVertexFormatFloat, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FLOAT32_FEATS, MVK_FMT_BUFFER_VTX_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32G32_UINT, MTLPixelFormatRG32Uint, MTLPixelFormatInvalid, MTLVertexFormatUInt2, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorUInt32, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32G32_SINT, MTLPixelFormatRG32Sint, MTLPixelFormatInvalid, MTLVertexFormatInt2, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorInt32, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32G32_SFLOAT, MTLPixelFormatRG32Float, MTLPixelFormatInvalid, MTLVertexFormatFloat2, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorFloat, MVK_FMT_COLOR_FLOAT32_FEATS, MVK_FMT_BUFFER_VTX_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32G32B32_UINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatUInt3, MTLVertexFormatInvalid, 1, 1, 12, kMVKFormatColorUInt32, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32G32B32_SINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInt3, MTLVertexFormatInvalid, 1, 1, 12, kMVKFormatColorInt32, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32G32B32_SFLOAT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatFloat3, MTLVertexFormatInvalid, 1, 1, 12, kMVKFormatColorFloat, MVK_FMT_COLOR_FLOAT32_FEATS, MVK_FMT_BUFFER_VTX_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32G32B32A32_UINT, MTLPixelFormatRGBA32Uint, MTLPixelFormatInvalid, MTLVertexFormatUInt4, MTLVertexFormatInvalid, 1, 1, 16, kMVKFormatColorUInt32, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32G32B32A32_SINT, MTLPixelFormatRGBA32Sint, MTLPixelFormatInvalid, MTLVertexFormatInt4, MTLVertexFormatInvalid, 1, 1, 16, kMVKFormatColorInt32, MVK_FMT_COLOR_INTEGER_FEATS, MVK_FMT_BUFFER_VTX_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R32G32B32A32_SFLOAT, MTLPixelFormatRGBA32Float, MTLPixelFormatInvalid, MTLVertexFormatFloat4, MTLVertexFormatInvalid, 1, 1, 16, kMVKFormatColorFloat, MVK_FMT_COLOR_FLOAT32_FEATS, MVK_FMT_BUFFER_VTX_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64_UINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64_SINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64_SFLOAT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 8, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64G64_UINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 16, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64G64_SINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 16, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64G64_SFLOAT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 16, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64G64B64_UINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 24, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64G64B64_SINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 24, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64G64B64_SFLOAT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 24, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64G64B64A64_UINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 32, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64G64B64A64_SINT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 32, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_R64G64B64A64_SFLOAT, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 32, kMVKFormatColorFloat, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_B10G11R11_UFLOAT_PACK32, MTLPixelFormatRG11B10Float, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );	// Vulkan packed is reversed
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_E5B9G9R9_UFLOAT_PACK32, MTLPixelFormatRGB9E5Float, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatColorFloat, MVK_FMT_E5B9G9R9_FEATS, MVK_FMT_E5B9G9R9_BUFFER_FEATS );	// Vulkan packed is reversed

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_D32_SFLOAT, MTLPixelFormatDepth32Float, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatDepthStencil, MVK_FMT_DEPTH_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_D32_SFLOAT_S8_UINT, MTLPixelFormatDepth32Float_Stencil8, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 5, kMVKFormatDepthStencil, MVK_FMT_DEPTH_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_S8_UINT, MTLPixelFormatStencil8, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 1, kMVKFormatDepthStencil, MVK_FMT_STENCIL_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_D16_UNORM, MTLPixelFormatDepth16Unorm, MTLPixelFormatDepth32Float, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 2, kMVKFormatDepthStencil, MVK_FMT_DEPTH_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_D16_UNORM_S8_UINT, MTLPixelFormatInvalid, MTLPixelFormatDepth16Unorm_Stencil8, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 3, kMVKFormatDepthStencil, MVK_FMT_DEPTH_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_D24_UNORM_S8_UINT, MTLPixelFormatDepth24Unorm_Stencil8, MTLPixelFormatDepth32Float_Stencil8, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatDepthStencil, MVK_FMT_DEPTH_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_X8_D24_UNORM_PACK32, MTLPixelFormatInvalid, MTLPixelFormatDepth24Unorm_Stencil8, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 1, 1, 4, kMVKFormatDepthStencil, MVK_FMT_DEPTH_FEATS, MVK_FMT_NO_FEATS );	// Vulkan packed is reversed

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC1_RGB_UNORM_BLOCK, MTLPixelFormatBC1_RGBA, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC1_RGB_SRGB_BLOCK, MTLPixelFormatBC1_RGBA_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC1_RGBA_UNORM_BLOCK, MTLPixelFormatBC1_RGBA, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC1_RGBA_SRGB_BLOCK, MTLPixelFormatBC1_RGBA_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC2_UNORM_BLOCK, MTLPixelFormatBC2_RGBA, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC2_SRGB_BLOCK, MTLPixelFormatBC2_RGBA_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC3_UNORM_BLOCK, MTLPixelFormatBC3_RGBA, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC3_SRGB_BLOCK, MTLPixelFormatBC3_RGBA_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC4_UNORM_BLOCK, MTLPixelFormatBC4_RUnorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC4_SNORM_BLOCK, MTLPixelFormatBC4_RSnorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC5_UNORM_BLOCK, MTLPixelFormatBC5_RGUnorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC5_SNORM_BLOCK, MTLPixelFormatBC5_RGSnorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC6H_UFLOAT_BLOCK, MTLPixelFormatBC6H_RGBUfloat, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC6H_SFLOAT_BLOCK, MTLPixelFormatBC6H_RGBFloat, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC7_UNORM_BLOCK, MTLPixelFormatBC7_RGBAUnorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_BC7_SRGB_BLOCK, MTLPixelFormatBC7_RGBAUnorm_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK, MTLPixelFormatETC2_RGB8, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK, MTLPixelFormatETC2_RGB8_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK, MTLPixelFormatETC2_RGB8A1, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK, MTLPixelFormatETC2_RGB8A1_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK, MTLPixelFormatEAC_RGBA8, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK, MTLPixelFormatEAC_RGBA8_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_EAC_R11_UNORM_BLOCK, MTLPixelFormatEAC_R11Unorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_EAC_R11_SNORM_BLOCK, MTLPixelFormatEAC_R11Snorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_EAC_R11G11_UNORM_BLOCK, MTLPixelFormatEAC_RG11Unorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_EAC_R11G11_SNORM_BLOCK, MTLPixelFormatEAC_RG11Snorm, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_4x4_UNORM_BLOCK, MTLPixelFormatASTC_4x4_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_4x4_SRGB_BLOCK, MTLPixelFormatASTC_4x4_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_5x4_UNORM_BLOCK, MTLPixelFormatASTC_5x4_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 5, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_5x4_SRGB_BLOCK, MTLPixelFormatASTC_5x4_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 5, 4, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_5x5_UNORM_BLOCK, MTLPixelFormatASTC_5x5_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 5, 5, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_5x5_SRGB_BLOCK, MTLPixelFormatASTC_5x5_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 5, 5, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_6x5_UNORM_BLOCK, MTLPixelFormatASTC_6x5_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 6, 5, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_6x5_SRGB_BLOCK, MTLPixelFormatASTC_6x5_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 6, 5, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_6x6_UNORM_BLOCK, MTLPixelFormatASTC_6x6_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 6, 6, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_6x6_SRGB_BLOCK, MTLPixelFormatASTC_6x6_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 6, 6, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_8x5_UNORM_BLOCK, MTLPixelFormatASTC_8x5_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 5, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_8x5_SRGB_BLOCK, MTLPixelFormatASTC_8x5_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 5, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_8x6_UNORM_BLOCK, MTLPixelFormatASTC_8x6_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 6, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_8x6_SRGB_BLOCK, MTLPixelFormatASTC_8x6_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 6, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_8x8_UNORM_BLOCK, MTLPixelFormatASTC_8x8_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 8, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_8x8_SRGB_BLOCK, MTLPixelFormatASTC_8x8_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 8, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_10x5_UNORM_BLOCK, MTLPixelFormatASTC_10x5_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 10, 5, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_10x5_SRGB_BLOCK, MTLPixelFormatASTC_10x5_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 10, 5, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_10x6_UNORM_BLOCK, MTLPixelFormatASTC_10x6_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 10, 6, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_10x6_SRGB_BLOCK, MTLPixelFormatASTC_10x6_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 10, 6, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_10x8_UNORM_BLOCK, MTLPixelFormatASTC_10x8_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 10, 8, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_10x8_SRGB_BLOCK, MTLPixelFormatASTC_10x8_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 10, 8, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_10x10_UNORM_BLOCK, MTLPixelFormatASTC_10x10_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 10, 10, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_10x10_SRGB_BLOCK, MTLPixelFormatASTC_10x10_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 10, 10, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_12x10_UNORM_BLOCK, MTLPixelFormatASTC_12x10_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 12, 10, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_12x10_SRGB_BLOCK, MTLPixelFormatASTC_12x10_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 12, 10, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_12x12_UNORM_BLOCK, MTLPixelFormatASTC_12x12_LDR, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 12, 12, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_ASTC_12x12_SRGB_BLOCK, MTLPixelFormatASTC_12x12_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 12, 12, 16, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );

	// Extension VK_IMG_format_pvrtc
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_PVRTC1_2BPP_UNORM_BLOCK_IMG, MTLPixelFormatPVRTC_RGBA_2BPP, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_PVRTC1_4BPP_UNORM_BLOCK_IMG, MTLPixelFormatPVRTC_RGBA_4BPP, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_PVRTC2_2BPP_UNORM_BLOCK_IMG, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 4, 8, kMVKFormatCompressed, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_PVRTC2_4BPP_UNORM_BLOCK_IMG, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_PVRTC1_2BPP_SRGB_BLOCK_IMG, MTLPixelFormatPVRTC_RGBA_2BPP_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_PVRTC1_4BPP_SRGB_BLOCK_IMG, MTLPixelFormatPVRTC_RGBA_4BPP_sRGB, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_COMPRESSED_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_PVRTC2_2BPP_SRGB_BLOCK_IMG, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 8, 4, 8, kMVKFormatCompressed, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_PVRTC2_4BPP_SRGB_BLOCK_IMG, MTLPixelFormatInvalid, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 4, 4, 8, kMVKFormatCompressed, MVK_FMT_NO_FEATS, MVK_FMT_NO_FEATS );

	// Future extension VK_KHX_color_conversion and Vulkan 1.1.
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_UNDEFINED, MTLPixelFormatGBGR422, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 2, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );
	MVK_ADD_VKFMT_STRUCT( VK_FORMAT_UNDEFINED, MTLPixelFormatBGRG422, MTLPixelFormatInvalid, MTLVertexFormatInvalid, MTLVertexFormatInvalid, 2, 1, 4, kMVKFormatColorFloat, MVK_FMT_COLOR_FEATS, MVK_FMT_BUFFER_FEATS );

	// When adding to this list, be sure to ensure _vkFormatCount is large enough for the format count
}

#define MVK_ADD_MTLPIXFMT_STRUCT(MTL_FMT, IOS_SINCE, MACOS_SINCE)  \
	MVKAssert(fmtIdx < _mtlPixelFormatCount, "Attempting to describe %d MTLPixelFormats, but only have space for %d. Increase the value of _mtlPixelFormatCount", fmtIdx + 1, _mtlPixelFormatCount);		\
	_mtlPixelFormatDescriptions[fmtIdx++] = { .mtlPixelFormat = MTL_FMT, VK_FORMAT_UNDEFINED, IOS_SINCE, MACOS_SINCE, #MTL_FMT }

void MVKPixelFormats::initMTLPixelFormatCapabilities() {

	mvkClear(_mtlPixelFormatDescriptions, _mtlPixelFormatCount);

	uint32_t fmtIdx = 0;

	// When adding to this list, be sure to ensure _mtlPixelFormatCount is large enough for the format count
	// MTLPixelFormatInvalid must come first.
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatInvalid, kMTLFmtNA, kMTLFmtNA );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatABGR4Unorm, 8.0, kMTLFmtNA );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatB5G6R5Unorm, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatA1BGR5Unorm, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBGR5A1Unorm, 8.0, kMTLFmtNA );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR8Unorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR8Snorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR8Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR8Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR8Unorm_sRGB, 8.0, kMTLFmtNA );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG8Unorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG8Snorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG8Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG8Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG8Unorm_sRGB, 8.0, kMTLFmtNA );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Unorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Snorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Unorm_sRGB, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBGRA8Unorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBGRA8Unorm_sRGB, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Unorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Snorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA8Unorm_sRGB, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBGR10A2Unorm, 11.0, 10.13 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGB10A2Unorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGB10A2Uint, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR16Unorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR16Snorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR16Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR16Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR16Float, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG16Unorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG16Snorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG16Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG16Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG16Float, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA16Unorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA16Snorm, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA16Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA16Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA16Float, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR32Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR32Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatR32Float, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG32Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG32Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG32Float, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA32Uint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA32Sint, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGBA32Float, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRG11B10Float, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatRGB9E5Float, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatDepth32Float, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatDepth32Float_Stencil8, 9.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatStencil8, 8.0, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatDepth16Unorm, kMTLFmtNA, 10.12 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatDepth24Unorm_Stencil8, kMTLFmtNA, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC1_RGBA, kMTLFmtNA, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC1_RGBA_sRGB, kMTLFmtNA, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC1_RGBA, kMTLFmtNA, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC1_RGBA_sRGB, kMTLFmtNA, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC2_RGBA, kMTLFmtNA, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC2_RGBA_sRGB, kMTLFmtNA, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC3_RGBA, kMTLFmtNA, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC3_RGBA_sRGB, kMTLFmtNA, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC4_RUnorm, kMTLFmtNA, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC4_RSnorm, kMTLFmtNA, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC5_RGUnorm, kMTLFmtNA, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC5_RGSnorm, kMTLFmtNA, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC6H_RGBUfloat, kMTLFmtNA, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC6H_RGBFloat, kMTLFmtNA, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC7_RGBAUnorm, kMTLFmtNA, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBC7_RGBAUnorm_sRGB, kMTLFmtNA, 10.11 );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatETC2_RGB8, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatETC2_RGB8_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatETC2_RGB8A1, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatETC2_RGB8A1_sRGB, 8.0, kMTLFmtNA );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatEAC_RGBA8, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatEAC_RGBA8_sRGB, 8.0, kMTLFmtNA );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatEAC_R11Unorm, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatEAC_R11Snorm, 8.0, kMTLFmtNA );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatEAC_RG11Unorm, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatEAC_RG11Snorm, 8.0, kMTLFmtNA );

	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_4x4_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_4x4_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_5x4_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_5x4_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_5x5_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_5x5_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_6x5_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_6x5_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_6x6_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_6x6_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_8x5_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_8x5_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_8x6_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_8x6_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_8x8_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_8x8_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_10x5_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_10x5_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_10x6_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_10x6_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_10x8_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_10x8_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_10x10_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_10x10_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_12x10_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_12x10_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_12x12_LDR, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatASTC_12x12_sRGB, 8.0, kMTLFmtNA );

	// Extension VK_IMG_format_pvrtc
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatPVRTC_RGBA_2BPP, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatPVRTC_RGBA_4BPP, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatPVRTC_RGBA_2BPP_sRGB, 8.0, kMTLFmtNA );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatPVRTC_RGBA_4BPP_sRGB, 8.0, kMTLFmtNA );

	// Future extension VK_KHX_color_conversion and Vulkan 1.1.
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatGBGR422, 8.0, 10.11 );
	MVK_ADD_MTLPIXFMT_STRUCT( MTLPixelFormatBGRG422, 8.0, 10.11 );

	// When adding to this list, be sure to ensure _mtlPixelFormatCount is large enough for the format count
}

#define MVK_ADD_MTLVTXFMT_STRUCT(MTL_VTX_FMT, VTX_IOS_SINCE, VTX_MACOS_SINCE)  \
	MVKAssert(fmtIdx < _mtlVertexFormatCount, "Attempting to describe %d MTLVertexFormats, but only have space for %d. Increase the value of _mtlVertexFormatCount", fmtIdx + 1, _mtlVertexFormatCount);		\
	_mtlVertexFormatDescriptions[fmtIdx++] = { .mtlVertexFormat = MTL_VTX_FMT, VK_FORMAT_UNDEFINED, VTX_IOS_SINCE, VTX_MACOS_SINCE, #MTL_VTX_FMT }

void MVKPixelFormats::initMTLVertexFormatCapabilities() {

	mvkClear(_mtlVertexFormatDescriptions, _mtlVertexFormatCount);

	uint32_t fmtIdx = 0;

	// When adding to this list, be sure to ensure _mtlVertexFormatCount is large enough for the format count
	// MTLVertexFormatInvalid must come first.
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatInvalid, kMTLFmtNA, kMTLFmtNA );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUCharNormalized, 11.0, 10.13 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatCharNormalized, 11.0, 10.13 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUChar, 11.0, 10.13 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatChar, 11.0, 10.13 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUChar2Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatChar2Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUChar2, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatChar2, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUChar3Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatChar3Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUChar3, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatChar3, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUChar4Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatChar4Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUChar4, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatChar4, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUChar4Normalized_BGRA, 11.0, 10.13 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUInt1010102Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatInt1010102Normalized, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUShortNormalized, 11.0, 10.13 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatShortNormalized, 11.0, 10.13 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUShort, 11.0, 10.13 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatShort, 11.0, 10.13 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatHalf, 11.0, 10.13 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUShort2Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatShort2Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUShort2, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatShort2, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatHalf2, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUShort3Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatShort3Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUShort3, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatShort3, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatHalf3, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUShort4Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatShort4Normalized, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUShort4, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatShort4, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatHalf4, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUInt, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatInt, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatFloat, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUInt2, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatInt2, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatFloat2, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUInt3, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatInt3, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatFloat3, 8.0, 10.11 );

	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatUInt4, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatInt4, 8.0, 10.11 );
	MVK_ADD_MTLVTXFMT_STRUCT( MTLVertexFormatFloat4, 8.0, 10.11 );

	// When adding to this list, be sure to ensure _mtlVertexFormatCount is large enough for the format count
}

// Populates the lookup maps that map Vulkan and Metal pixel formats to one-another.
void MVKPixelFormats::buildFormatMaps() {

	// Set all VkFormats, MTLPixelFormats, and MTLVertexFormats to undefined/invalid
	mvkClear(_vkFormatDescIndicesByVkFormatsCore, _vkFormatCoreCount);
	mvkClear(_mtlFormatDescIndicesByMTLPixelFormats, _mtlPixelFormatCount);
	mvkClear(_mtlFormatDescIndicesByMTLVertexFormats, _mtlVertexFormatCount);

	// Build lookup table for MTLPixelFormat specs
	for (uint32_t fmtIdx = 0; fmtIdx < _mtlPixelFormatCount; fmtIdx++) {
		MTLPixelFormat fmt = _mtlPixelFormatDescriptions[fmtIdx].mtlPixelFormat;
		if (fmt) { _mtlFormatDescIndicesByMTLPixelFormats[fmt] = fmtIdx; }
	}

	// Build lookup table for MTLVertexFormat specs
	for (uint32_t fmtIdx = 0; fmtIdx < _mtlVertexFormatCount; fmtIdx++) {
		MTLVertexFormat fmt = _mtlVertexFormatDescriptions[fmtIdx].mtlVertexFormat;
		if (fmt) { _mtlFormatDescIndicesByMTLVertexFormats[fmt] = fmtIdx; }
	}

	// Iterate through the VkFormat descriptions, populate the lookup maps and back pointers,
	// and validate the Metal formats for the platform and OS.
	for (uint32_t fmtIdx = 0; fmtIdx < _vkFormatCount; fmtIdx++) {
		MVKVkFormatDesc& vkDesc = _vkFormatDescriptions[fmtIdx];
		VkFormat vkFmt = vkDesc.vkFormat;
		if (vkFmt) {
			// Create a lookup between the Vulkan format and an index to the format info.
			// For core Vulkan format values, which are small and consecutive, use a simple lookup array.
			// For extension format values, which can be large, use a map.
			if (vkFmt < _vkFormatCoreCount) {
				_vkFormatDescIndicesByVkFormatsCore[vkFmt] = fmtIdx;
			} else {
				_vkFormatDescIndicesByVkFormatsExt[vkFmt] = fmtIdx;
			}

			// Populate the back reference from the Metal formats to the Vulkan format.
			// Validate the corresponding Metal formats for the platform, and clear them
			// in the Vulkan format if not supported.
			if (vkDesc.mtlPixelFormat) {
				auto& mtlDesc = getMTLPixelFormatDesc(vkDesc.mtlPixelFormat);
				if ( !mtlDesc.vkFormat ) { mtlDesc.vkFormat = vkFmt; }
				if ( !mtlDesc.isSupported() ) { vkDesc.mtlPixelFormat = MTLPixelFormatInvalid; }
			}
			if (vkDesc.mtlPixelFormatSubstitute) {
				auto& mtlDesc = getMTLPixelFormatDesc(vkDesc.mtlPixelFormatSubstitute);
				if ( !mtlDesc.isSupported() ) { vkDesc.mtlPixelFormatSubstitute = MTLPixelFormatInvalid; }
			}
			if (vkDesc.mtlVertexFormat) {
				auto& mtlDesc = getMTLVertexFormatDesc(vkDesc.mtlVertexFormat);
				if ( !mtlDesc.vkFormat ) { mtlDesc.vkFormat = vkFmt; }
				if ( !mtlDesc.isSupported() ) { vkDesc.mtlVertexFormat = MTLVertexFormatInvalid; }
			}
			if (vkDesc.mtlVertexFormatSubstitute) {
				auto& mtlDesc = getMTLVertexFormatDesc(vkDesc.mtlVertexFormatSubstitute);
				if ( !mtlDesc.isSupported() ) { vkDesc.mtlVertexFormatSubstitute = MTLVertexFormatInvalid; }
			}
		}
	}
}

// Modifies the format capability tables based on the capabilities of the specific MTLDevice
void MVKPixelFormats::modifyFormatCapabilitiesForMTLDevice(id<MTLDevice> mtlDevice) {
	if ( !mtlDevice ) { return; }

#if MVK_MACOS
	if ( !mtlDevice.isDepth24Stencil8PixelFormatSupported ) {
		disableMTLPixelFormat(MTLPixelFormatDepth24Unorm_Stencil8);
	}
#endif
}

void MVKPixelFormats::disableMTLPixelFormat(MTLPixelFormat mtlFormat) {
	getVkFormatDesc(mtlFormat).mtlPixelFormat = MTLPixelFormatInvalid;
}


#pragma mark -
#pragma mark Unit Testing

// Validate the functionality of this class against the previous format data within MoltenVK.
// This is a temporary function to confirm that converting to using this class matches existing behaviour at first.
void MVKPixelFormats::test() {
	if (_apiObject) { return; }		// Only test default platform formats

#define MVK_TEST_FMT(V1, V2)	testFmt(V1, V2, fd.name, #V1)

	MVKLogInfo("Starting testing formats");
	for (uint32_t fmtIdx = 0; fmtIdx < _vkFormatCount; fmtIdx++) {
		auto& fd = _vkFormatDescriptions[fmtIdx];
		VkFormat vkFmt = fd.vkFormat;
		MTLPixelFormat mtlFmt = fd.mtlPixelFormat;

		if (fd.vkFormat) {
			if (fd.isSupportedOrSubstitutable()) {
				MVKLogInfo("Testing %s", fd.name);

				MVK_TEST_FMT(vkFormatIsSupported(vkFmt), mvkVkFormatIsSupported(vkFmt));
				MVK_TEST_FMT(mtlPixelFormatIsSupported(mtlFmt), mvkMTLPixelFormatIsSupported(mtlFmt));
				MVK_TEST_FMT(mtlPixelFormatIsDepthFormat(mtlFmt), mvkMTLPixelFormatIsDepthFormat(mtlFmt));
				MVK_TEST_FMT(mtlPixelFormatIsStencilFormat(mtlFmt), mvkMTLPixelFormatIsStencilFormat(mtlFmt));
				MVK_TEST_FMT(mtlPixelFormatIsPVRTCFormat(mtlFmt), mvkMTLPixelFormatIsPVRTCFormat(mtlFmt));
				MVK_TEST_FMT(getFormatTypeFromVkFormat(vkFmt), mvkFormatTypeFromVkFormat(vkFmt));
				MVK_TEST_FMT(getFormatTypeFromMTLPixelFormat(mtlFmt), mvkFormatTypeFromMTLPixelFormat(mtlFmt));
				MVK_TEST_FMT(getMTLPixelFormatFromVkFormat(vkFmt), mvkMTLPixelFormatFromVkFormat(vkFmt));
				MVK_TEST_FMT(getVkFormatFromMTLPixelFormat(mtlFmt), mvkVkFormatFromMTLPixelFormat(mtlFmt));
				MVK_TEST_FMT(getVkFormatBytesPerBlock(vkFmt), mvkVkFormatBytesPerBlock(vkFmt));
				MVK_TEST_FMT(getMTLPixelFormatBytesPerBlock(mtlFmt), mvkMTLPixelFormatBytesPerBlock(mtlFmt));
				MVK_TEST_FMT(getVkFormatBlockTexelSize(vkFmt), mvkVkFormatBlockTexelSize(vkFmt));
				MVK_TEST_FMT(getMTLPixelFormatBlockTexelSize(mtlFmt), mvkMTLPixelFormatBlockTexelSize(mtlFmt));
				MVK_TEST_FMT(getVkFormatBytesPerTexel(vkFmt), mvkVkFormatBytesPerTexel(vkFmt));
				MVK_TEST_FMT(getMTLPixelFormatBytesPerTexel(mtlFmt), mvkMTLPixelFormatBytesPerTexel(mtlFmt));
				MVK_TEST_FMT(getVkFormatBytesPerRow(vkFmt, 4), mvkVkFormatBytesPerRow(vkFmt, 4));
				MVK_TEST_FMT(getMTLPixelFormatBytesPerRow(mtlFmt, 4), mvkMTLPixelFormatBytesPerRow(mtlFmt, 4));
				MVK_TEST_FMT(getVkFormatBytesPerLayer(vkFmt, 256, 4), mvkVkFormatBytesPerLayer(vkFmt, 256, 4));
				MVK_TEST_FMT(getMTLPixelFormatBytesPerLayer(mtlFmt, 256, 4), mvkMTLPixelFormatBytesPerLayer(mtlFmt, 256, 4));
				MVK_TEST_FMT(getVkFormatProperties(vkFmt), mvkVkFormatProperties(vkFmt));
				MVK_TEST_FMT(strcmp(getVkFormatName(vkFmt), mvkVkFormatName(vkFmt)), 0);
				MVK_TEST_FMT(strcmp(getMTLPixelFormatName(mtlFmt), mvkMTLPixelFormatName(mtlFmt)), 0);
				MVK_TEST_FMT(getMTLClearColorFromVkClearValue(VkClearValue(), vkFmt),
							 mvkMTLClearColorFromVkClearValue(VkClearValue(), vkFmt));

				MVK_TEST_FMT(getVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsageUnknown, mtlFmt),
							 mvkVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsageUnknown, mtlFmt));
				MVK_TEST_FMT(getVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsageShaderRead, mtlFmt),
							 mvkVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsageShaderRead, mtlFmt));
				MVK_TEST_FMT(getVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsageShaderWrite, mtlFmt),
							 mvkVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsageShaderWrite, mtlFmt));
				MVK_TEST_FMT(getVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsageRenderTarget, mtlFmt),
							 mvkVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsageRenderTarget, mtlFmt));
				MVK_TEST_FMT(getVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsagePixelFormatView, mtlFmt),
							 mvkVkImageUsageFlagsFromMTLTextureUsage(MTLTextureUsagePixelFormatView, mtlFmt));

				MVK_TEST_FMT(getMTLVertexFormatFromVkFormat(vkFmt), mvkMTLVertexFormatFromVkFormat(vkFmt));

			} else {
				MVKLogInfo("%s not supported or substitutable on this device.", fd.name);
			}
		}
	}
	MVKLogInfo("Finished testing formats.\n");
}

template<typename T>
void MVKPixelFormats::testFmt(const T v1, const T v2, const char* fmtName, const char* funcName) {
	MVKAssert(mvkAreEqual(&v1,&v2), "Results not equal for format %s on test %s.", fmtName, funcName);
}
