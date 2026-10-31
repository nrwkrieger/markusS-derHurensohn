package dev.visuals.overhaul.visual;

/** CPU-seitige Berechnung für Tageszeit-Farbkurven, Sättigung und Kontrast. */
public final class ColorGrading {
    private ColorGrading() {}

    /** dayTime 0..1 (0 = Mitternacht, 0.25 = Sonnenaufgang, 0.5 = Mittag, 0.75 = Sonnenuntergang). */
    public static float[] timeOfDayTint(float dayTime, float dawnWarmth, float nightCoolness) {
        float dawn = bell(dayTime, 0.25f, 0.08f) * dawnWarmth;
        float dusk = bell(dayTime, 0.75f, 0.08f) * dawnWarmth;
        float night = (1f - smooth(dayTime, 0.22f, 0.28f)) * (1f - smooth(dayTime, 0.72f, 0.78f)) * nightCoolness;

        float r = 1f + 0.25f * (dawn + dusk) - 0.15f * night;
        float g = 1f + 0.05f * (dawn + dusk) - 0.05f * night;
        float b = 1f - 0.10f * (dawn + dusk) + 0.25f * night;
        return new float[]{r, g, b};
    }

    public static float[] applySatContrast(float[] rgb, float saturation, float contrast) {
        float lum = 0.2126f * rgb[0] + 0.7152f * rgb[1] + 0.0722f * rgb[2];
        float[] out = new float[3];
        for (int i = 0; i < 3; i++) {
            float s = lum + (rgb[i] - lum) * saturation;
            out[i] = clamp01((s - 0.5f) * contrast + 0.5f);
        }
        return out;
    }

    private static float bell(float x, float center, float width) {
        float d = (x - center) / width;
        return (float) Math.exp(-d * d);
    }

    private static float smooth(float x, float edge0, float edge1) {
        float t = clamp01((x - edge0) / (edge1 - edge0));
        return t * t * (3 - 2 * t);
    }

    private static float clamp01(float v) {
        return Math.max(0f, Math.min(1f, v));
    }
}
