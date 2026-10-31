package dev.visuals.overhaul.ui;

import net.minecraft.client.gui.DrawContext;

/** Zeichnet ein halbtransparentes Glas-Panel mit Lichtkante und Schatten. */
public final class GlassPanel {
    private GlassPanel() {}

    public static void draw(DrawContext ctx, int x, int y, int w, int h, float opacity) {
        int a = (int) (Math.clamp(opacity, 0f, 1f) * 255);
        int body = (a << 24) | 0x1A2433;
        int top = (Math.min(255, a + 40) << 24) | 0xFFFFFF;
        int shadow = (Math.min(255, a / 2) << 24) | 0x000000;

        ctx.fill(x + 3, y + 4, x + w + 3, y + h + 4, shadow);
        ctx.fill(x, y, x + w, y + h, body);
        ctx.fill(x, y, x + w, y + 1, top);
        ctx.fill(x, y + 1, x + w, y + 2, (Math.min(255, a / 3) << 24) | 0xFFFFFF);
        int edge = (Math.min(255, a + 20) << 24) | 0xFFFFFF;
        ctx.fill(x, y, x + 1, y + h, edge);
        ctx.fill(x + w - 1, y, x + w, y + h, edge);
        ctx.fill(x, y + h - 1, x + w, y + h, edge);
    }
}
