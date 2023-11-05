using Shared.Util;
using TestLib.Assert;

class DateValuesTest {

  (:test)
  static function empty(l) {
    var v = new Shared.DateValues(null, 3);
    Assert.equal(0, v.size());
    return true;
  }

  (:test)
  static function add(l) {
    var v = new Shared.DateValues(null, 3);
    v.add(new Shared.DateValue(3, 4));
    Assert.equal(1, v.size());
    Assert.equal(3, v.getDateSec(0));
    Assert.equal(4, v.getValue(0));
    return true;
  }

  (:test)
  static function resizeGrow(l) {
    var v = new Shared.DateValues(null, 3);
    v.add(new Shared.DateValue(3, 30));
    v.add(new Shared.DateValue(4, 40));
    v.add(new Shared.DateValue(5, 50));
    Assert.equal(3, v.size());
    Assert.equal(3, v.getDateSec(0));
    Assert.equal(4, v.getDateSec(1));
    Assert.equal(5, v.getDateSec(2));

    v.resize(4);
    Assert.equal(3, v.size());
    Assert.equal(3, v.getDateSec(0));
    Assert.equal(4, v.getDateSec(1));
    Assert.equal(5, v.getDateSec(2));

    v.add(new Shared.DateValue(6, 60));
    Assert.equal(3, v.getDateSec(0));
    Assert.equal(4, v.getDateSec(1));
    Assert.equal(5, v.getDateSec(2));
    Assert.equal(6, v.getDateSec(3));
    return true;
  }

  (:test)
  static function resizeShrink(l) {
    var v = new Shared.DateValues(null, 3);
    v.add(new Shared.DateValue(3, 30));
    v.add(new Shared.DateValue(4, 40));
    v.add(new Shared.DateValue(5, 50));
    Assert.equal(3, v.size());
    Assert.equal(3, v.getDateSec(0));
    Assert.equal(4, v.getDateSec(1));
    Assert.equal(5, v.getDateSec(2));

    v.resize(2);
    Assert.equal(2, v.size());
    Assert.equal(4, v.getDateSec(0));
    Assert.equal(5, v.getDateSec(1));

    return true;
  }

  (:test)
  static function medianDeltaSec(l) {
    var v = new Shared.DateValues(null, 10);
    v.add(new Shared.DateValue(3, 30));
    v.add(new Shared.DateValue(4, 40));
    Assert.equal(1, v.medianDeltaSec());
    
    v.add(new Shared.DateValue(5, 50));
    v.add(new Shared.DateValue(7, 50));
    v.add(new Shared.DateValue(8, 50));
    Assert.equal(1, v.medianDeltaSec());

    return true;
  }

  (:test)
  static function medianDeltaMinute(l) {
  var v = new Shared.DateValues(null, 10);
  Assert.equal(null, v.medianDeltaSec());

  v.add(new Shared.DateValue(30, 30));
  Assert.equal(null, v.medianDeltaSec());

  v.add(new Shared.DateValue(140, 40));
  Assert.equal(2, v.medianDeltaMinute());
  
  v.add(new Shared.DateValue(205, 50));
  v.add(new Shared.DateValue(330, 50));
  v.add(new Shared.DateValue(390, 50));
  v.add(new Shared.DateValue(440, 50));
  Assert.equal(1, v.medianDeltaMinute());

  return true;
  }

  (:test)
  static function copy(l) {
    var v = new Shared.DateValues([3, 4, null, null], 1);
    Assert.equal(1, v.size());
    Assert.equal(3, v.getDateSec(0));
    Assert.equal(4, v.getValue(0));
    return true;
  }

  (:test)
  static function truncate(l) {
    var v = new Shared.DateValues(null, 3);
    v.add(new Shared.DateValue(3, 4));
    v.add(new Shared.DateValue(5, 6));
    v.add(new Shared.DateValue(7, 8));
    Assert.equal(3, v.size());
    v.truncateTo(1);
    Assert.equal(2, v.size());
    Assert.equal(5, v.getDateSec(0));
    Assert.equal(6, v.getValue(0));
    Assert.equal(7, v.getDateSec(1));
    Assert.equal(8, v.getValue(1));

    v.add(new Shared.DateValue(9, 10));
    Assert.equal(3, v.size());
    Assert.equal(5, v.getDateSec(0));
    Assert.equal(9, v.getDateSec(2));

    v.add(new Shared.DateValue(11, 12));
    Assert.equal(3, v.size());
    Assert.equal(7, v.getDateSec(0));
    Assert.equal(11, v.getDateSec(2));

    return true;
  }

  (:test)
  static function overflow(l) {
    var v = new Shared.DateValues(null, 3);
    v.add(new Shared.DateValue(3, 4));
    v.add(new Shared.DateValue(5, 6));
    v.add(new Shared.DateValue(7, 8));
    v.add(new Shared.DateValue(9, 10));
    Assert.equal(3, v.size());
    Assert.equal(5, v.getDateSec(0));
    Assert.equal(6, v.getValue(0));
    return true;
  }

  (:test)
  static function toHexString(l) {
    var v = new Shared.DateValues(null, 3);
    v.add(new Shared.DateValue(3, 256 + 255));
    v.add(new Shared.DateValue(5, 6));
    Assert.equal("00000003000001ff0000000500000006", v.toHexString());
    return true;
  }

  (:test)
  static function fromHexString(l) {
    var v = new Shared.DateValues(null, 3);
    v.fromHexString("00000003000001ff0000000500000006");
    Assert.equal(2, v.size());
    Assert.equal(3, v.getDateSec(0));
    Assert.equal(255+256, v.getValue(0));
    Assert.equal(5, v.getDateSec(1));
    Assert.equal(6, v.getValue(1));
    return true;
  }
}