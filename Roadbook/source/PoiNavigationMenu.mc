import Toybox.Lang;

using Shared.Log;
using Toybox.Communications;
using Toybox.PersistedContent;
using Toybox.Position;
using Toybox.System;
using Toybox.WatchUi as Ui;

// A focusable version of the compact POI table. Selecting a row opens an action menu: the rider
// can either hand the destination to Garmin navigation or search for it on the paired phone.
class PoiNavigationMenu extends Ui.Menu2 {
  function initialize(pois as Array, title as String) {
    Menu2.initialize({ :title => "Select: " + title });
    for (var i = 0; i < pois.size(); i++) {
      var poi = pois[i] as Dictionary;
      var displayName = poi[:displayName];
      var detail = formatDistance(poi[:distanceMeter] as Number);
      var offRouteMeter = poi[:offRouteMeter];
      if (offRouteMeter != null) {
        detail += " / " + formatDistance(offRouteMeter as Number) + " off";
      }
      addItem(new Ui.MenuItem(
          displayName == null ? poi[:name] as String : displayName as String,
          detail,
          i,
          {}));
    }
  }

  private function formatDistance(distanceMeter as Number) as String {
    if (distanceMeter < 1000) {
      return distanceMeter + " m";
    }
    return (distanceMeter / 1000.0).format("%.1f") + " km";
  }
}

class PoiNavigationMenuDelegate extends Ui.Menu2InputDelegate {
  private var pois as Array;
  private var onFailure as Method;

  function initialize(pois as Array, onFailure as Method) {
    Ui.Menu2InputDelegate.initialize();
    me.pois = pois;
    me.onFailure = onFailure;
  }

  function onSelect(item as Ui.MenuItem) as Void {
    var index = item.getId() as Number;
    if (index < 0 || index >= pois.size()) {
      fail("POI is no longer available");
      return;
    }
    var poi = pois[index] as Dictionary;
    var menu = new PoiActionMenu(poi);
    Ui.pushView(menu, new PoiActionMenuDelegate(poi, onFailure), Ui.SLIDE_UP);
  }

  private function fail(message as String) as Void {
    onFailure.invoke(message);
    Ui.popView(Ui.SLIDE_DOWN);
  }
}

class PoiActionMenu extends Ui.Menu2 {
  function initialize(poi as Dictionary) {
    Menu2.initialize({ :title => poi[:name] as String });
    addItem(new Ui.MenuItem("Navigate on Garmin", null, :garmin, {}));
    addItem(new Ui.MenuItem("Open in Google Maps", "on phone", :googleMaps, {}));
  }
}

class PoiActionMenuDelegate extends Ui.Menu2InputDelegate {
  private static const TAG = "PoiNavigation";

  private var poi as Dictionary;
  private var onFailure as Method;

  function initialize(poi as Dictionary, onFailure as Method) {
    Ui.Menu2InputDelegate.initialize();
    me.poi = poi;
    me.onFailure = onFailure;
  }

  function onSelect(item as Ui.MenuItem) as Void {
    switch (item.getId()) {
      case :garmin:
        navigateOnGarmin();
        return;
      case :googleMaps:
        openGoogleMaps();
        return;
    }
  }

  private function navigateOnGarmin() as Void {
    var latitude = poi[:latitude];
    var longitude = poi[:longitude];
    if (latitude == null || longitude == null) {
      fail("Update server to navigate");
      return;
    }
    try {
      // Remember the app-owned waypoint IDs first: saveWaypoint() returns Void, so the newly
      // created object is found by the ID that was not present before the save.
      var oldIds = [] as Array<Number>;
      var before = PersistedContent.getAppWaypoints();
      var beforeItem = before.next();
      while (beforeItem != null) {
        var oldWaypoint = beforeItem as PersistedContent.Waypoint;
        oldIds.add(oldWaypoint.getId());
        beforeItem = before.next();
      }

      var location = new Position.Location({
          :latitude => latitude as Double,
          :longitude => longitude as Double,
          :format => :degrees });
      PersistedContent.saveWaypoint(location, { :name => poi[:name] as String });

      var saved = null;
      var after = PersistedContent.getAppWaypoints();
      var afterItem = after.next();
      while (afterItem != null) {
        var waypoint = afterItem as PersistedContent.Waypoint;
        if (!containsId(oldIds, waypoint.getId())) {
          saved = waypoint;
          break;
        }
        afterItem = after.next();
      }
      if (saved == null) {
        fail("Could not open Garmin navigation");
        return;
      }

      Log.i(TAG, "Launching navigation to " + (poi[:name] as String));
      System.exitTo((saved as PersistedContent.Waypoint).toIntent());
    } catch (e) {
      Log.i(TAG, "Navigation failed: " + e.getErrorMessage());
      fail("Could not open Garmin navigation");
    }
  }

  // openWebPage does not open the page on the Edge. Garmin Connect Mobile posts a phone
  // notification, and accepting it opens this search in the phone's browser or Google Maps app.
  // The viewport form keeps the POI location centered and zoomed in. Type remains the first search
  // term because OSM and Google frequently use different names, with the OSM name as an additional
  // hint when the POI has a real one.
  private function openGoogleMaps() as Void {
    var latitude = poi[:latitude];
    var longitude = poi[:longitude];
    if (latitude == null || longitude == null) {
      fail("Update server to open Maps");
      return;
    }
    try {
      var url = "https://www.google.com/maps/search/" + googleMapsQuery() + "/@" +
          (latitude as Double).format("%.6f") + "," +
          (longitude as Double).format("%.6f") + ",17z";
      Communications.openWebPage(url, {}, null);
      Log.i(TAG, "Sent Google Maps search to phone for " + (poi[:name] as String));
    } catch (e) {
      Log.i(TAG, "Google Maps failed: " + e.getErrorMessage());
      fail("Could not contact phone");
    }
  }

  private function googleMapsType() as String {
    var kind = poi[:kind];
    if (kind == null) {
      return "point+of+interest";
    }
    switch (kind as String) {
      case "water":
        return "drinking+water";
      case "toilet":
        return "public+toilet";
      case "restaurant":
        return "restaurant";
      case "bar":
        return "bar";
      case "bakery":
        return "bakery";
    }
    return "point+of+interest";
  }

  private function googleMapsQuery() as String {
    var type = googleMapsType();
    var name = poi[:name] as String;
    var kind = poi[:kind];
    // The server substitutes these labels when OSM has no name. Repeating one contributes no
    // search information, while a genuine name helps Google match the specific nearby result.
    if ((kind != null && (kind as String).equals("water") && name.equals("Drinking water")) ||
        (kind != null && (kind as String).equals("toilet") && name.equals("Public toilet")) ||
        (kind != null && (kind as String).equals("restaurant") && name.equals("Restaurant")) ||
        (kind != null && (kind as String).equals("bar") && name.equals("Bar")) ||
        (kind != null && (kind as String).equals("bakery") && name.equals("Bakery"))) {
      return type;
    }
    return type + "+" + Communications.encodeURL(name);
  }

  private function containsId(ids as Array<Number>, id as Number) as Boolean {
    for (var i = 0; i < ids.size(); i++) {
      if (ids[i] == id) {
        return true;
      }
    }
    return false;
  }

  private function fail(message as String) as Void {
    onFailure.invoke(message);
    Ui.popView(Ui.SLIDE_DOWN);
  }
}
