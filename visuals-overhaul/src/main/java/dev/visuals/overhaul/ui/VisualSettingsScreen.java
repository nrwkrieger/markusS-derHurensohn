package dev.visuals.overhaul.ui;

import dev.visuals.overhaul.VisualsOverhaulClient;
import dev.visuals.overhaul.config.VisualConfig;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.gui.widget.ButtonWidget;
import net.minecraft.text.Text;

import java.util.List;
import java.util.function.Consumer;
import java.util.function.Supplier;

public class VisualSettingsScreen extends Screen {
    private final Screen parent;
    private int activeTab = 0;

    private static final List<String> TABS = List.of(
            "Licht", "Himmel & Nebel", "Wasser", "Post-Processing", "Farben", "Partikel");

    public VisualSettingsScreen(Screen parent) {
        super(Text.literal("Visuals Overhaul"));
        this.parent = parent;
    }

    @Override
    protected void init() {
        int panelW = Math.min(520, this.width - 40);
        int left = (this.width - panelW) / 2;

        int tabW = panelW / TABS.size();
        for (int i = 0; i < TABS.size(); i++) {
            final int idx = i;
            this.addDrawableChild(ButtonWidget.builder(Text.literal(TABS.get(i)), b -> {
                activeTab = idx;
                this.clearAndInit();
            }).dimensions(left + i * tabW, 40, tabW - 2, 20).build());
        }

        VisualConfig c = VisualsOverhaulClient.CONFIG;
        int y = 80;
        for (Slider s : slidersFor(activeTab, c)) {
            this.addDrawableChild(new FloatSlider(left + 20, y, panelW - 40, s.label(),
                    s.min(), s.max(), s.getter(), s.setter()));
            y += 26;
        }

        this.addDrawableChild(ButtonWidget.builder(Text.literal("Fertig"), b -> {
            c.save();
            this.client.setScreen(parent);
        }).dimensions(this.width / 2 - 60, this.height - 30, 120, 20).build());
    }

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        ctx.fill(0, 0, this.width, this.height, 0x66000000);

        int panelW = Math.min(520, this.width - 40);
        int left = (this.width - panelW) / 2;
        GlassPanel.draw(ctx, left - 10, 30, panelW + 20, this.height - 70,
                VisualsOverhaulClient.CONFIG.glassOpacity);

        super.render(ctx, mouseX, mouseY, delta);
        ctx.drawCenteredTextWithShadow(this.textRenderer, this.title, this.width / 2, 12, 0xFFFFFFFF);
    }

    @Override
    public boolean shouldPause() {
        return false;
    }

    private record Slider(String label, float min, float max,
                          Supplier<Float> getter, Consumer<Float> setter) {}

    private static List<Slider> slidersFor(int tab, VisualConfig c) {
        return switch (tab) {
            case 0 -> List.of(
                    new Slider("Belichtung", 0.2f, 2.0f, () -> c.exposure, v -> c.exposure = v),
                    new Slider("Bloom-Stärke", 0f, 1f, () -> c.bloomStrength, v -> c.bloomStrength = v),
                    new Slider("Bloom-Schwelle", 0f, 1f, () -> c.bloomThreshold, v -> c.bloomThreshold = v),
                    new Slider("Lichtstrahlen", 0f, 1f, () -> c.godRays, v -> c.godRays = v));
            case 1 -> List.of(
                    new Slider("Nebeldichte", 0f, 3f, () -> c.fogDensity, v -> c.fogDensity = v),
                    new Slider("Nebelbeginn", 0f, 1f, () -> c.fogStart, v -> c.fogStart = v),
                    new Slider("Himmelhelligkeit", 0f, 2f, () -> c.skyBrightness, v -> c.skyBrightness = v));
            case 2 -> List.of(
                    new Slider("Wellenstärke", 0f, 2f, () -> c.waterWaveStrength, v -> c.waterWaveStrength = v),
                    new Slider("Klarheit", 0f, 1f, () -> c.waterClarity, v -> c.waterClarity = v));
            case 3 -> List.of(
                    new Slider("Sättigung", 0f, 2f, () -> c.saturation, v -> c.saturation = v),
                    new Slider("Kontrast", 0f, 2f, () -> c.contrast, v -> c.contrast = v),
                    new Slider("Vignette", 0f, 1f, () -> c.vignette, v -> c.vignette = v),
                    new Slider("Filmkorn", 0f, 1f, () -> c.grain, v -> c.grain = v),
                    new Slider("Chromat. Aberration", 0f, 1f, () -> c.chromaticAberration, v -> c.chromaticAberration = v));
            case 4 -> List.of(
                    new Slider("Morgenwärme", 0f, 1f, () -> c.dawnWarmth, v -> c.dawnWarmth = v),
                    new Slider("Nachtkühle", 0f, 1f, () -> c.nightCoolness, v -> c.nightCoolness = v));
            case 5 -> List.of(
                    new Slider("Partikelhelligkeit", 0f, 2f, () -> c.particleBrightness, v -> c.particleBrightness = v),
                    new Slider("Partikelgröße", 0.2f, 3f, () -> c.particleSize, v -> c.particleSize = v));
            default -> List.of();
        };
    }
}
