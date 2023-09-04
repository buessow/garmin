using TestLib.Assert;
using Toybox.Time;
using Shared;
using Shared.Util;

(:Test)
class CsvParserTest {
  (:test)
  function emptyReturnsNull(l) {
    try {
      var p = new Shared.CsvParser("");
      Assert.equal(null, p.next(0));
      Assert.equal(null, p.next(1));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  function oneLine(l) {
    try {
      var p = new Shared.CsvParser("A\tB");
      Assert.equal("A", p.next(0));
      Assert.equal("B", p.next(0));
      Assert.equal(null, p.next(0));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

   (:test)
  function twoLines(l) {
    try {
      var p = new Shared.CsvParser("A\tB\n\rC\tD");
      Assert.equal(true, p.more());
      Assert.equal("A", p.next(0));
      Assert.equal(true, p.more());
      Assert.equal("B", p.next(0));
      Assert.equal("C", p.next(0));
      Assert.equal("D", p.next(0));
      Assert.equal(null, p.next(0));
      Assert.equal(false, p.more());
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

   (:test)
  function twoLinesSkipTooFar(l) {
    try {
      var p = new Shared.CsvParser("A\tB\n\rC\tD");
      Assert.equal("A", p.next(0));
      Assert.equal(null, p.next(1));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

   (:test)
  function twoLinesSkipLiner(l) {
    try {
      var p = new Shared.CsvParser("A\tB\n\rC\tD");
      p.nextLine();
      Assert.equal("C", p.next(0));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }


  (:test)
  function oneLineSkip(l) {
    try {
      var p = new Shared.CsvParser("A\tB");
      Assert.equal("B", p.next(1));
      Assert.equal(null, p.next(0));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }

  (:test)
  function oneLineQuoted(l) {
    try {
      var p = new Shared.CsvParser("\"A\"\t\"B\"");
      Assert.equal("A", p.next(0));
      Assert.equal("B", p.next(0));
      Assert.equal(null, p.next(0));
      return true;
    } catch (e) {
      l.error(e.getErrorMessage());
      e.printStackTrace();
      throw e;
    }
  }
}