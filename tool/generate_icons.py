"""生成应用图标（Android / iOS / Web 三端全部尺寸）。

用法（需要 Pillow，项目本身不依赖它，只是这个一次性工具需要）：

    python tool/generate_icons.py

设计：品牌主色 `#F47D62` 的竖向渐变底 + 白色购物袋图形。
- Android / Web 普通图标：圆角方形（半径 22%）
- iOS：直角满幅（iOS 自己会裁圆角，且不允许透明通道）
- Web maskable：满幅底 + 缩小到 72% 的图形，留出系统裁切的安全区

所有尺寸都从 4096px 的超采样母版缩下来，边缘不会出现锯齿。
母版会同时写到 `docs/icon/app_icon_1024.png`，改图标时先改母版再重跑本脚本。
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent

# 品牌色：与 lib/constants/app_theme.dart 的 AppColors.primary 一致
TOP_COLOR = (255, 143, 113)
BOTTOM_COLOR = (232, 94, 69)

SUPERSAMPLE = 4096


def _gradient_background(size: int) -> Image.Image:
    """竖向渐变底。逐行插值，4096 行的一次性开销可以忽略。"""
    img = Image.new("RGB", (1, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(size - 1, 1)
        color = tuple(
            round(TOP_COLOR[i] + (BOTTOM_COLOR[i] - TOP_COLOR[i]) * t) for i in range(3)
        )
        draw.point((0, y), fill=color)
    return img.resize((size, size), Image.NEAREST)


def _bag_layer(size: int, scale: float) -> Image.Image:
    """白色购物袋图形，画在透明层上，方便按比例缩放后居中合成。

    图形以画布中心为原点定义（单位是相对尺寸），这样调 scale 时它始终居中：
    - 提手：上半圆环，半径 0.125、线宽 0.048，圆心在袋身顶边中点
    - 袋身：宽 0.42、高 0.295 的圆角矩形
    整体竖向跨度约 0.445，横向 0.42。
    """
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    white = (255, 255, 255, 255)

    def px(value: float) -> float:
        return size / 2 + value * size * scale

    body_top = -0.0725
    body_bottom = 0.2225
    handle_r = 0.125
    handle_w = max(1, round(0.048 * size * scale))

    # 提手：上半圆环
    draw.arc(
        [
            px(-handle_r),
            px(body_top - handle_r),
            px(handle_r),
            px(body_top + handle_r),
        ],
        start=180,
        end=360,
        fill=white,
        width=handle_w,
    )

    # 袋身：圆角矩形
    draw.rounded_rectangle(
        [px(-0.21), px(body_top), px(0.21), px(body_bottom)],
        radius=0.055 * size * scale,
        fill=white,
    )
    return layer


def _rounded_mask(size: int, radius_ratio: float) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=int(size * radius_ratio), fill=255
    )
    return mask


def render(size: int, *, rounded: bool, glyph_scale: float) -> Image.Image:
    """渲染一张图标：渐变底 + 白色购物袋。"""
    base = _gradient_background(size).convert("RGBA")
    base.alpha_composite(_bag_layer(size, glyph_scale))
    if rounded:
        base.putalpha(_rounded_mask(size, 0.22))
    return base


def save(image: Image.Image, target: Path, size: int, *, opaque: bool = False) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    out = image.resize((size, size), Image.LANCZOS)
    if opaque:
        # 透明像素直接 convert("RGB") 会变成黑色，必须先确认源图是不透明的
        if out.mode == "RGBA" and out.getchannel("A").getextrema()[0] < 255:
            raise ValueError(
                f"{target.name} 要求不透明输出，但源图带透明像素："
                "Web PWA 图标请传 square_master，iOS 同理"
            )
        out = out.convert("RGB")
    out.save(target, "PNG", optimize=True)
    print(f"  {target.relative_to(ROOT)}  {size}x{size}")


def main() -> None:
    rounded_master = render(SUPERSAMPLE, rounded=True, glyph_scale=1.0)
    square_master = render(SUPERSAMPLE, rounded=False, glyph_scale=1.0)
    maskable_master = render(SUPERSAMPLE, rounded=False, glyph_scale=0.72)

    # 母版（1024，供文档与后续修改使用）
    save(rounded_master, ROOT / "docs/icon/app_icon_1024.png", 1024)

    print("Android:")
    for folder, size in (
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ):
        save(
            rounded_master,
            ROOT / f"android/app/src/main/res/{folder}/ic_launcher.png",
            size,
        )

    print("Web:")
    save(rounded_master, ROOT / "web/favicon.png", 16)
    # PWA 图标交给系统蒙版裁切，必须是满幅不透明的图（圆角会留下透明角，转 RGB 后变黑）
    save(square_master, ROOT / "web/icons/Icon-192.png", 192, opaque=True)
    save(square_master, ROOT / "web/icons/Icon-512.png", 512, opaque=True)
    save(maskable_master, ROOT / "web/icons/Icon-maskable-192.png", 192)
    save(maskable_master, ROOT / "web/icons/Icon-maskable-512.png", 512)

    print("iOS:")
    icon_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    with open(icon_dir / "Contents.json", encoding="utf-8") as fh:
        contents = json.load(fh)
    # 按「文件名」逐个写：不同 entry 可能落到同一像素尺寸
    # （如 20x20@2x 与 40x40@1x 都是 40px），只按尺寸去重会漏掉文件，
    # 那些漏掉的文件会继续留着旧的模板图标。
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        point = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        pixels = round(point * scale)
        # iOS 不允许图标带透明通道，统一转 RGB
        save(square_master, icon_dir / filename, pixels, opaque=True)


if __name__ == "__main__":
    main()
