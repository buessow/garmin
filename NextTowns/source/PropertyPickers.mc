import Toybox.Lang;

using Toybox.Application.Properties;
using Toybox.WatchUi as Ui;

// Generic TextPicker glue: writes the entered text to a named property and notifies the caller,
// so SettingsMenu doesn't need one delegate class per free-text field.
class PropertyTextPickerDelegate extends Ui.TextPickerDelegate {
  private var propertyKey as String;
  private var onChanged as Method() as Void;

  function initialize(propertyKey as String, onChanged as Method() as Void) {
    Ui.TextPickerDelegate.initialize();
    me.propertyKey = propertyKey;
    me.onChanged = onChanged;
  }

  function onTextEntered(text as String, changed as Boolean) as Boolean {
    if (changed) {
      Properties.setValue(propertyKey, text);
      onChanged.invoke();
    }
    Ui.popView(Ui.SLIDE_DOWN);
    return true;
  }

  function onCancel() as Boolean {
    Ui.popView(Ui.SLIDE_DOWN);
    return true;
  }
}

// A Menu2 of fixed numeric choices (e.g. "2 towns", "500 m") - used instead of Ui.NumberPicker,
// since NumberPicker only offers domain-specific modes (distance, weight, time, ...) with no
// plain small-integer mode, and a short preset list is faster to use on a bike computer than
// dialing a wide numeric range to an exact value anyway.
class ChoiceMenu extends Ui.Menu2 {
  function initialize(title as String, choices as Array<Number>, unit as String) {
    Menu2.initialize({ :title => title });
    for (var i = 0; i < choices.size(); i++) {
      addItem(new Ui.MenuItem(choices[i].toString() + " " + unit, null, choices[i], {}));
    }
  }
}

class ChoiceMenuDelegate extends Ui.Menu2InputDelegate {
  private var propertyKey as String;
  private var onChanged as Method() as Void;

  function initialize(propertyKey as String, onChanged as Method() as Void) {
    Ui.Menu2InputDelegate.initialize();
    me.propertyKey = propertyKey;
    me.onChanged = onChanged;
  }

  function onSelect(item as Ui.MenuItem) as Void {
    Properties.setValue(propertyKey, item.getId() as Number);
    onChanged.invoke();
    Ui.popView(Ui.SLIDE_DOWN);
  }

  function onBack() as Void {
    Ui.popView(Ui.SLIDE_DOWN);
  }
}
