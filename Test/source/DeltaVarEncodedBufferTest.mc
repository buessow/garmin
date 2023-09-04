using TestLib.Assert;
using Shared;

class DeltaVarEncodedBufferTest {

/*
  (:test)
  static function testOne(l) {
  try {
    var b = new Shared.DeltaVarEncodedBuffer(16, 1);
    b.add1(10);
    Assert.equal(b.toArray(), [10]);

    b.add1(201);
    b.add1(8);
    b.add1(700);
    Assert.equal([10, 201, 8, 700], b.toArray());
    Assert.equal([10, 201, 8, 700], b.toArray());
    Assert.equal(7, b.byteSize());
    Assert.equal([700], b.toArrayTail(1));
    Assert.equal([8, 700], b.toArrayTail(2));
    Assert.equal([10, 201, 8, 700], b.toArrayTail(6));
    // Assert.equal("14fe028103e80a,000002bc", b.toEncodedString());
    return true;
    } catch (e) {
      e.printStackTrace(); return false;
      }
  }

  (:test)
  static function testTwo(l) {
    var b = new Shared.DeltaVarEncodedBuffer(16, 2);
    b.add2(10, 100);
    Assert.equal([10, 100], b.toArray());

    b.add2(201, 101);
    b.add2(8, 10);
    Assert.equal([10, 100, 201, 101, 8, 10], b.toArray());
    Assert.equal([201, 101, 8, 10], b.toArrayTail(2));
    Assert.equal([10, 100, 201, 101, 8, 10], b.toArrayTail(10));
    Assert.equal(10, b.byteSize());
    return true;
  }


   (:test)
  static function testLarge(l) {
    try {
      var b = new Shared.DeltaVarEncodedBuffer(16, 1);
      b.add1(0x7fffffff);
      b.add1(0x80000000);
      Assert.equal([0x7fffffff, 0x80000000], b.toArray());
      return true;
    } catch (e) {
      e.printStackTrace();
      return false;
    }
  }

   (:test)
  static function testMany(l) {
    var start = 100;
    var count = 150;
    var b = new Shared.DeltaVarEncodedBuffer(800, 1);
    var sign = 1;
    var e = [];
    for (var i = start; i < count; i++) {
      b.add1(sign * i / 2);
      e.add(sign * i / 2);
      sign = -sign;
    }
    Assert.equal(e, b.toArray());
    return true;
  }

  (:test)
  static function testRemove(l) {
    try {
      var b = new Shared.DeltaVarEncodedBuffer(16, 1);
      b.add1(10);
      b.add1(12);
      b.add1(14);
      Assert.equal([10, 12, 14], b.toArray());
      b.removeFirst();
      Assert.equal([12, 14], b.toArray());
      b.removeFirst();
      Assert.equal([14], b.toArray());
      b.removeFirst();
      Assert.equal([], b.toArray());
      return true;
    } catch (e) {
      e.printStackTrace();
      return false;
    }
  }

  (:test)
  static function testRemove2(l) {
    var b = new Shared.DeltaVarEncodedBuffer(16, 2);
    b.add2(10, 13);
    b.add2(12, -3);
    Assert.equal([10, 13, 12, -3], b.toArray());
    b.removeFirst();
    Assert.equal([12, -3], b.toArray());
    b.removeFirst();
    Assert.equal([], b.toArray());
    return true;
  }

  (:test)
  static function testOverflow(l) {
    var b = new Shared.DeltaVarEncodedBuffer(8, 1);
    b.add1(130);
    Assert.equal(6, b.remaining());
    b.add1(0);
    Assert.equal(4, b.remaining());
    b.add1(-128);
    Assert.equal(2, b.remaining());
    Assert.equal([130, 0, -128], b.toArray());
    b.add1(1);
    Assert.equal(0, b.remaining());
    Assert.equal([130, 0, -128, 1], b.toArray());
    b.add1(-129);
    Assert.equal([0, -128, 1, -129], b.toArray());
    b.add1(229);
    Assert.equal([-128, 1, -129, 229], b.toArray());
    return true;
  }

  (:test)
  static function testSetRaw(l) {
    try {
      var values = [
         1511690926, 146, 1511691226, 149, 1511691526, 151, 1511691826, 153,
         1511692126, 155, 1511692426, 157, 1511692726, 156, 1511693026, 158,
         1511693326, 158, 1511693626, 159, 1511693926, 159, 1511694226, 160];
      var raw = [
         -2881560441697023268L, 289593787831289348L, 349033389971735768L,
         -2882298435690244095L, 145478582575563268L];
      var rawb = [
          220, 202, 212, 161, 11, 164, 2, 216, 4, 6, 216, 4, 4, 216, 4, 4, 216, 4, 4,
          216, 4, 4, 216, 4, 1, 216, 4, 4, 216, 4, 0, 216, 4, 2, 216, 4, 0, 216, 4, 2]b;
      var b = new Shared.DeltaVarEncodedBuffer(8, 1);
      b.setRaw([1511694226,160], rawb, 40);
      Assert.equal(values, b.toArray());
      Assert.equal(values, b.toArrayTail(values.size()));
      Assert.equal([1511693926, 159, 1511694226, 160], b.toArrayTail(2));
      return true;

    } catch (e) {
      e.printStackTrace();
      return false;
    }
  }

  (:test)
  static function testSetRawBase64(l) {
    try {
      var b = new Shared.DeltaVarEncodedBuffer(0, 2);
      b.setRawBase64("FCAODSkH");
      Assert.equal([10, 16, 17, 9, -4, 5], b.toArray());
      Assert.equal([-4, 5], b.toArrayTail(1));
      return true;
    } catch (e) {
      e.printStackTrace();
      return false;
    }
  }

  (:test)
  static function testSetRawBase64_2(l) {
    try {
      var b = new Shared.DeltaVarEncodedBuffer(0, 2);
      b.setRawBase64("1OqPzgumAtoEEtgEEtwEBNYEBtYEANoEBNQEBOAEBNgEBtAEAtoECtgEBtgEAuYEAM4EAtgEBdQEB94EDdIEC+IEA9oEAdoEBsoECtgECA==");
      Assert.equal(50, b.toArray().size());
      Assert.equal([1558313642,147,1558313943,156,1558314243,165,1558314545,167,1558314844,170,1558315143,170,1558315444,172,1558315742,174,1558316046,176,1558316346,179,1558316642,180,1558316943,185,1558317243,188,1558317543,189,1558317850,189,1558318145,190,1558318445,187,1558318743,183,1558319046,176,1558319343,170,1558319648,168,1558319949,167,1558320250,170,1558320543,175,1558320843,179], b.toArray());
      Assert.equal([1558320543,175,1558320843,179], b.toArrayTail(2));
      return true;
    } catch (e) {
      e.printStackTrace();
      return false;
    }
  }
  */


  (:test)
  static function testDecodeBase64(l) {
    try {
      var a = Shared.DeltaVarEncoder.decodeBase64(2, "FCAODSkH");
      Assert.equal([10, 16, 17, 9, -4, 5], a);
      return true;
    } catch (e) {
      e.printStackTrace();
      return false;
    }
  }

  (:test)
  static function testDecodeBase64_2(l) {
    try {
      var a = Shared.DeltaVarEncoder.decodeBase64(
        2,
        "1OqPzgumAtoEEtgEEtwEBNYEBtYEANoEBNQEBOAEBNgEBtAEAtoECtgEBtgEAuYEAM4EAtgEBdQEB94EDdIEC+IEA9oEAdoEBsoECtgECA==");
      Assert.equal(
          [1558313642,147,1558313943,156,1558314243,165,1558314545,167,
           1558314844,170,1558315143,170,1558315444,172,1558315742,174,
           1558316046,176,1558316346,179,1558316642,180,1558316943,185,
           1558317243,188,1558317543,189,1558317850,189,1558318145,190,
           1558318445,187,1558318743,183,1558319046,176,1558319343,170,
           1558319648,168,1558319949,167,1558320250,170,1558320543,175,
           1558320843,179],
          a);
      return true;
    } catch (e) {
      e.printStackTrace();
      return false;
    }
  }
}
