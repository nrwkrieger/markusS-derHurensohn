package dev.visuals.overhaul;

import dev.visuals.overhaul.config.VisualConfig;
import dev.visuals.overhaul.visual.OpenSettingsKeybind;
import net.fabricmc.api.ClientModInitializer;

public class VisualsOverhaulClient implements ClientModInitializer {
    public static final String MOD_ID = "visuals-overhaul";
    public static VisualConfig CONFIG;

    @Override
    public void onInitializeClient() {
        CONFIG = VisualConfig.load();
        OpenSettingsKeybind.register();
    }
}
