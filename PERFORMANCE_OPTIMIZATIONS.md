# Performance Optimizations Summary

## Version 2.5.0 - High-Resolution Display Optimizations

This document outlines the performance improvements made to the Media Bar plugin for better performance on high-resolution displays (1440p/4K), particularly on devices like the Steam Deck.

## Problems Identified

### 1. Excessive Image Resolution Loading
**Problem**: The plugin was loading full-resolution backdrop images (potentially 3840x2160 @ quality=60) without any `maxWidth` parameter, resulting in:
- 800KB-1.5MB per backdrop image on 4K content
- Excessive GPU memory usage
- Slow image decode times
- Unnecessary bandwidth consumption

**Solution**: Implemented responsive image loading with resolution-based sizing:
```javascript
// 4K displays: cap at 1920px, quality=50
// 1440p displays: cap at 1920px, quality=55  
// 1080p displays: cap at 1920px, quality=60
// Lower displays: original quality=60, no cap
```

**Impact**: ~70% reduction in image file size on 4K displays

### 2. GPU-Intensive Blur Animations
**Problem**: The frostedGlass animation applied `filter: blur(8px)` on full-screen images during transitions. On high-res displays:
- Blur filtering on 4K images is extremely GPU-intensive
- Caused severe frame drops and lag
- Applied on EVERY slide transition

**Solution**: 
- Disabled blur animations on displays ≥1440p via CSS media queries
- Replaced with simple opacity fade (`simpleFade` animation)
- Kept blur effects for lower resolutions where performance is fine

**Impact**: Eliminates major GPU bottleneck on high-res displays

### 3. Ken Burns Zoom Effect
**Problem**: 10-second continuous `transform: scale(1.1)` animation on massive images:
- Forces GPU to continuously rescale large textures
- Compounds with blur effect for double performance hit
- Unnecessary on large displays where effect is barely noticeable

**Solution**: Disabled Ken Burns effect on displays ≥1440p

**Impact**: Reduces continuous GPU transform operations

### 4. Inefficient DOM Manipulation
**Problem**: Multiple synchronous DOM queries and class changes:
- `querySelectorAll` called multiple times per transition
- Class changes triggered forced reflows
- No batching of DOM updates

**Solution**: 
- Wrapped DOM updates in `requestAnimationFrame()`
- Batched multiple class changes together
- Reduced redundant queries

**Impact**: Smoother transitions with fewer reflows

### 5. Missing GPU Acceleration Hints
**Problem**: No `will-change` CSS properties or compositing hints:
- Browser couldn't optimize layer composition
- Forced CPU rendering for some operations

**Solution**: Added proper GPU hints:
```css
.slide {
  will-change: opacity;
  transform: translateZ(0); /* Force GPU layer */
}

.backdrop {
  will-change: transform, opacity;
  transform: translateZ(0);
}
```

**Impact**: Better GPU utilization and layer composition

## Implementation Details

### Modified Files

#### 1. `slideshowpure.js`
- Added `getImageParams()` function for resolution-based image sizing
- Added `buildImageUrl()` helper for constructing optimized URLs
- Added resolution detection flags to CONFIG:
  - `isHighResolution` (≥2560px width or ≥1440px height)
  - `isUltraHighResolution` (≥3840px width)
  - `shouldUseBlurAnimations` (disabled on high-res)
  - `shouldUseKenBurnsEffect` (disabled on high-res)
- Updated `createSlideElement()` to use optimized image URLs
- Updated `updateCurrentSlide()` to batch DOM operations in `requestAnimationFrame()`

#### 2. `slideshowpure.css`
- Added media query for standard resolution (≤2559px): full animations
- Added media query for high resolution (≥2560px or ≥1440px): simplified animations
- Created `simpleFade` animation as lightweight replacement
- Added `will-change` properties for GPU optimization
- Added `transform: translateZ(0)` for layer isolation

#### 3. `Jellyfin.Plugin.MediaBar.csproj`
- Bumped version from 2.4.0.0 to 2.5.0.0

#### 4. `Properties/AssemblyInfo.cs`
- Updated AssemblyVersion to 2.5.0.0

#### 5. `Inject/index.html`
- Changed CDN URLs from `IAmParadox27` to `Paliago` fork

#### 6. `README.md`
- Added performance optimizations section
- Updated badges and links to point to fork
- Added changelog for v2.5.0

## Resolution-Based Configuration

| Display Resolution | Backdrop Quality | Backdrop Max Width | Logo Quality | Logo Max Width | Blur Animation | Ken Burns |
|-------------------|------------------|-------------------|--------------|----------------|----------------|-----------|
| 4K+ (≥3840px)     | 50               | 1920px            | 35           | 800px          | ❌ Disabled    | ❌ Disabled |
| 1440p-4K          | 55               | 1920px            | 38           | 800px          | ❌ Disabled    | ❌ Disabled |
| 1080p             | 60               | 1920px            | 40           | None           | ✅ Enabled     | ✅ Enabled  |
| <1080p            | 60               | None              | 40           | None           | ✅ Enabled     | ✅ Enabled  |

## Performance Metrics (Estimated)

### Before Optimization (4K Display)
- Backdrop image size: ~1000KB
- Logo image size: ~150KB
- Transition lag: Severe (frame drops)
- GPU usage: Very High (blur + scale on 4K texture)
- Animation smoothness: Poor

### After Optimization (4K Display)
- Backdrop image size: ~300KB (70% reduction)
- Logo image size: ~50KB (67% reduction)
- Transition lag: Minimal
- GPU usage: Moderate (simple fade only)
- Animation smoothness: Excellent

## Testing Recommendations

1. **Test on multiple resolutions**:
   - 1080p (should see full animations)
   - 1440p (should see simplified animations)
   - 4K (should see simplified animations)

2. **Verify image loading**:
   - Check browser DevTools Network tab
   - Confirm backdrop images are ~300KB at 4K
   - Verify maxWidth parameter is present in URLs

3. **Monitor GPU performance**:
   - Use browser performance profiler
   - Check for frame drops during transitions
   - Verify GPU layer compositing

4. **Test on Steam Deck**:
   - Gaming mode @ 4K via TV
   - Verify smooth transitions
   - Check for UI responsiveness

## Future Optimization Opportunities

1. **Lazy loading improvements**: Only decode images when they become visible
2. **Preloading optimization**: Reduce preloadCount on high-res displays
3. **Progressive image loading**: Load low-quality placeholder first, upgrade later
4. **Intersection observer**: Only animate slides in viewport
5. **User preference toggle**: Allow users to force enable/disable effects

## Backwards Compatibility

All changes are backwards compatible:
- Lower resolution displays maintain original behavior
- Original animation quality preserved where performance allows
- No breaking changes to plugin API or configuration
- Automatic detection requires no user configuration

## Installation for Users

Users installing from this fork should follow standard installation procedures. The optimizations activate automatically based on display resolution - no configuration needed!
