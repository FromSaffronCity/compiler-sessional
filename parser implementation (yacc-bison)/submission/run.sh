yaccFile=1605023.y
lexFile=1605023.l
inputFile=input.txt
####################################################################
#Created by Mir Mahathir Mohammad 1605011
####################################################################
DIR="$(cd "$(dirname "$0")" && pwd)"
cd $DIR
bison -d -y -v ./$yaccFile
g++ -w -c -o ./y.o ./y.tab.c
flex -o ./lex.yy.c ./$lexFile
g++ -fpermissive -w -c -o ./l.o ./lex.yy.c
g++ -o ./a.out ./y.o ./l.o -lfl -ly	
./a.out ./input.txt
