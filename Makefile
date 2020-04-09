all:	memr.com

memr.com: memr.asm
	zasm -uw --asm8080 memr.asm
	mv memr.rom memr.com
	hexdump -v -e '"%06.6_ao: " 8/1 "%03o " "\n"' memr.com > memr.oct
	zasm -uw -x --asm8080 memr.asm

