package dev.visuals.overhaul.ui;

import net.minecraft.client.gui.widget.SliderWidget;
import net.minecraft.text.Text;

import java.util.function.Consumer;
import java.util.function.Supplier;

/** Slider, der einen Float-Wert auf ein Min/Max-Intervall abbildet. */
public class FloatSlider extends SliderWidget {
    private final String label;
    private final float min, max;
    private final Consumer<Float> setter;

    public FloatSlider(int x, int y, int w, String label, float min, float max,
                       Supplier<Float> getter, Consumer<Float> setter) {
        super(x, y, w, 20, Text.empty(), (getter.get() - min) / (max - min));
        this.label = label;
        this.min = min;
        this.max = max;
        this.setter = setter;
        updateMessage();
    }

    private float value() {
        return min + (float) this.value * (max - min);
    }

    @Override
    protected void updateMessage() {
        this.setMessage(Text.literal(label + ": " + String.format("%.2f", value())));
    }

    @Override
    protected void applyValue() {
        setter.accept(value());
    }
}
