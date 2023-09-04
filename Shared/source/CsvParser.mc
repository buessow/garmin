using Toybox.StringUtil;
/*
module Shared {
class CsvParser {
  var input;
  var pos = 0;
  var tokenStart;
  var tokenEnd;

  enum { eol, eof, tok, err }

  function initialize(input) {
    me.input = input.toCharArray();
  }

  function more() {
    return pos < input.size();
  }

  hidden function skip() {
    tokenStart = pos;
    tokenEnd = pos;
    if (pos < input.size() && input[pos] == '\"') {
      pos++;
      tokenStart++;
      while (pos < input.size()) {
        if (input[pos] == '\"') {
          tokenEnd = pos;
          pos++;
          break;
        }
        pos++;
      }
    }
    while (true) {
      if (pos == input.size()) {
        return eof;
      } else if (input[pos] == '\n') {
        pos++;
        if (pos < input.size() && input[pos] == '\r') {
          pos++;
        }
        return eol;
      } else if (input[pos] == '\t') {
        pos++;
        return tok;
      }
      pos++;
      tokenEnd++;
    }
  }

  function nextLine() {
    while (skip() == tok) {}
  }

  function next(skip) {
    for (var i = 0; i < skip; i++) {
      if (skip() != tok) {
        return null;
      }
    }
    skip();
    return StringUtil.charArrayToString(input.slice(tokenStart, tokenEnd));
  }
}
}
*/