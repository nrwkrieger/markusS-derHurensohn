package dev.visuals.overhaul.config;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import net.fabricmc.loader.api.FabricLoader;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/** Alle Visual-Einstellungen. Wird als JSON im config-Ordner gespeichert. */
public class VisualConfig {
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private static final Path FILE = FabricLoader.getInstance().getConfigDir().resolve("visuals-overhaul.json");

    // Licht
    public float exposure = 1.0f;
    public float bloomStrength = 0.35f;
    public float bloomThreshold = 0.8f;
    public float godRays = 0.0f;

    // Himmel & Nebel
    public float fogDensity = 1.0f;
    public float fogStart = 0.8f;
    public float skyBrightness = 1.0f;

    // Wasser
    public float waterWaveStrength = 1.0f;
    public float waterClarity = 0.5f;

    // Post-Processing
    public float saturation = 1.0f;
    public float contrast = 1.0f;
    public float vignette = 0.0f;
    public float grain = 0.0f;
    public float chromaticAberration = 0.0f;

    // Farben (Tageszeit-Kurven)
    public float dawnWarmth = 0.5f;
    public float nightCoolness = 0.5f;

    // Partikel
    public float particleBrightness = 1.0f;
    public float particleSize = 1.0f;

    // UI
    public float glassOpacity = 0.55f;

    public static VisualConfig load() {
        try {
            if (Files.exists(FILE)) {
                return GSON.fromJson(Files.readString(FILE), VisualConfig.class);
            }
        } catch (IOException e) {
            System.err.println("[VisualsOverhaul] Config konnte nicht gelesen werden: " + e.getMessage());
        }
        VisualConfig defaults = new VisualConfig();
        defaults.save();
        return defaults;
    }

    public void save() {
        try {
            Files.createDirectories(FILE.getParent());
            Files.writeString(FILE, GSON.toJson(this));
        } catch (IOException e) {
            System.err.println("[VisualsOverhaul] Config konnte nicht gespeichert werden: " + e.getMessage());
        }
    }
}
