NAME = toy
LLVM_CONFIG = /usr/bin/llvm-config-12

NO_WARNING =  -Wno-return-type \
	-Wno-c++17-compat-deprecated-writable-strings \
	-Wno-deprecated-register \
	-Wno-switch \

CXXFLAGS = `$(LLVM_CONFIG) --cppflags` -std=c++17 $(NO_WARNING)
LDFLAGS = `$(LLVM_CONFIG) --ldflags`
LIBS = `$(LLVM_CONFIG) --libs --system-libs`

OBJS = parser.o scanner.o ast.o utils.o main.o Codegen.o ccalc.o

all: $(NAME)

parser.cpp: ${NAME}.y
	bison -d -o parser.cpp ${NAME}.y

parser.hpp: parser.cpp

scanner.cpp: ${NAME}.l
	flex -o scanner.cpp ${NAME}.l

%.o: %.cpp ast.h Codegen.h utils.h ccalc.h
	g++ -c $(CXXFLAGS) -g -o $@ $< 

$(NAME): $(OBJS)
	g++ -o $@ $(OBJS) $(LIBS) $(LDFLAGS)

debug:
	bison -d -o parser.cpp ${NAME}.y -v

