%option 8bit noyywrap yylineno stack

%{
  #include <algorithm>
  #include <iostream>
  #include <cctype>

  bool all_caps(const std::string &s) {
    return std::none_of(s.begin(), s.end(), ::islower);
  }

  // Convert lowerCamelCase and UpperCamelCase strings to lower_with_underscore.
  std::string convert(std::string &&camelCase) {
    std::string str(1, tolower(camelCase[0]));

    // First place underscores between contiguous lower and upper case letters.
    // For example, `_LowerCamelCase` becomes `_Lower_Camel_Case`.
    for (auto it = camelCase.begin() + 1; it != camelCase.end(); ++it) {
      if (isupper(*it) && *(it-1) != '_' && islower(*(it-1))) {
        str += "_";
      }
      str += *it;
    }

    // Then convert it to lower case.
    std::transform(str.begin(), str.end(), str.begin(), ::tolower);

    return str;
  }
%}

%x X_STRING X_COMMENT X_INCLUDE
%%

\"                          ECHO; yy_push_state(X_STRING);
<X_STRING>\\\"              ECHO;
<X_STRING>\\\\              ECHO;
<X_STRING>\"                ECHO; yy_pop_state();
<X_STRING>.                 ECHO;

"//".*$                     ECHO;

"/*"                        ECHO; yy_push_state(X_COMMENT);
<X_COMMENT>"/*"             ECHO; yy_push_state(X_COMMENT);
<X_COMMENT>"*/"             ECHO; yy_pop_state();
<X_COMMENT>.|\n             ECHO;

#include                    ECHO; yy_push_state(X_INCLUDE);

<INITIAL,X_INCLUDE>[a-zA-Z_][a-zA-Z0-9_]*     {
                             std::string id(yytext);
                             if (all_caps(id))
                               std::cout << id << std::flush;
                             else
                               std::cout << convert(std::move(id)) << std::flush;
                           }

<X_INCLUDE>\n              ECHO; yy_pop_state();

.|\n                       ECHO;

%%

int main() {
  return yylex();
}
