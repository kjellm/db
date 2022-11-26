class SqlParser
macro
  BLANK         [\ \t\n]+
rule
  {BLANK}       # no action
  (?i:select)   { [:SELECT, text] }
  (?i:from)     { [:FROM, text] }
  (?i:where)    { [:WHERE, text] }
  (?i:or)       { [:OR, text] }
  (?i:and)      { [:AND, text] }
  \d+           { [:VALUE, Integer(text, 10)] }
  \w+           { [:NAME, text.to_sym] }
  .             { [text, text] }
inner
end
