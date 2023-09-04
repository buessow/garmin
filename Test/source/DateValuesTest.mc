using Shared.Util;
using TestLib.Assert;

class DateValuesTest {

  (:test)
  static function empty(l) {
   try {
      var v = new Shared.DateValues(null, 3);
      Assert.equal(0, v.size());
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  static function add(l) {
   try {
      var v = new Shared.DateValues(null, 3);
      v.add(new Shared.DateValue(3, 4));
      Assert.equal(1, v.size());
      Assert.equal(3, v.getDateSec(0));
      Assert.equal(4, v.getValue(0));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  static function copy(l) {
   try {
      var v = new Shared.DateValues([3, 4, null, null], 2);
      Assert.equal(1, v.size());
      Assert.equal(3, v.getDateSec(0));
      Assert.equal(4, v.getValue(0));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  static function truncate(l) {
   try {
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
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  static function overflow(l) {
   try {
      var v = new Shared.DateValues(null, 3);
      v.add(new Shared.DateValue(3, 4));
      v.add(new Shared.DateValue(5, 6));
      v.add(new Shared.DateValue(7, 8));
      v.add(new Shared.DateValue(9, 10));
      Assert.equal(3, v.size());
      Assert.equal(5, v.getDateSec(0));
      Assert.equal(6, v.getValue(0));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  static function toHexString(l) {
   try {
      var v = new Shared.DateValues(null, 3);
      v.add(new Shared.DateValue(3, 256 + 255));
      v.add(new Shared.DateValue(5, 6));
      Assert.equal("00000003000001ff0000000500000006", v.toHexString());
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  static function fromHexString(l) {
   try {
      var v = new Shared.DateValues(null, 3);
      v.fromHexString("00000003000001ff0000000500000006");
      Assert.equal(2, v.size());
      Assert.equal(3, v.getDateSec(0));
      Assert.equal(255+256, v.getValue(0));
      Assert.equal(5, v.getDateSec(1));
      Assert.equal(6, v.getValue(1));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

}