package dev.visuals.overhaul.visual;

import dev.visuals.overhaul.ui.VisualSettingsScreen;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import org.lwjgl.glfw.GLFW;

public final class OpenSettingsKeybind {
    private OpenSettingsKeybind() {}

    private static final KeyBinding OPEN = KeyBindingHelper.registerKeyBinding(new KeyBinding(
            "key.visuals-overhaul.open", InputUtil.Type.KEYSYM, GLFW.GLFW_KEY_V,
            "category.visuals-overhaul"));

    public static void register() {
        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            while (OPEN.wasPressed()) {
                client.setScreen(new VisualSettingsScreen(client.currentScreen));
            }
        });
    }
}
