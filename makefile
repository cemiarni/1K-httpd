
linux:
	yasm -f elf64 http.asm
	ld -o http http.o
	strip -s http

macosx:
	yasm -f macho64 -D MACOSX http.asm
	ld -o http http.o
	strip -s http
