using Shared.Util;
using TestLib.Assert;

class UtilTest {
  (:test)
  static function testMax(l) {
    Assert.equal(3, Util.max(1, 3));
    return true;
  }

  (:test)
  static function testMin(l) {
    Assert.equal(1, Util.min(1, 3));
    return true;
  }

  (:test)
  static function testAbs(l) {
    Assert.equal(1, Util.abs(1));
    Assert.equal(1, Util.abs(-1));
    return true;
  }

  (:test)
  static function epochToString(l) {
    try {
    Assert.equal("1970-01-01T01:00:10", Util.epochToString(10));
    return true;
    } catch (e) {
      e.printStackTrace();
      return false;
    }
  }

//  static class CompareFirst {
//    function invoke(a, b) {
//      return a[0]  < b[0];
//    }
//  }

//  (:test)
//  static function testFind(l) {
//    Assert.equal(3, Util.find([[1,3], [2,2]], new CompareFirst())[1]);
//    return true;
//  }
}