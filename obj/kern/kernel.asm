
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	 orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	 movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 60 1a 10 f0 	movl   $0xf0101a60,(%esp)
f0100055:	e8 05 0a 00 00       	call   f0100a5f <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 34 07 00 00       	call   f01007bb <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 7c 1a 10 f0 	movl   $0xf0101a7c,(%esp)
f0100092:	e8 c8 09 00 00       	call   f0100a5f <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 40 29 11 f0       	mov    $0xf0112940,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 02 15 00 00       	call   f01015c7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 97 1a 10 f0 	movl   $0xf0101a97,(%esp)
f01000d9:	e8 81 09 00 00       	call   f0100a5f <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 ba 07 00 00       	call   f01008b0 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 44 29 11 f0 00 	cmpl   $0x0,0xf0112944
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 44 29 11 f0    	mov    %esi,0xf0112944

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 b2 1a 10 f0 	movl   $0xf0101ab2,(%esp)
f010012c:	e8 2e 09 00 00       	call   f0100a5f <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 ef 08 00 00       	call   f0100a2c <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ee 1a 10 f0 	movl   $0xf0101aee,(%esp)
f0100144:	e8 16 09 00 00       	call   f0100a5f <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 5b 07 00 00       	call   f01008b0 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ca 1a 10 f0 	movl   $0xf0101aca,(%esp)
f0100176:	e8 e4 08 00 00       	call   f0100a5f <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 a2 08 00 00       	call   f0100a2c <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ee 1a 10 f0 	movl   $0xf0101aee,(%esp)
f0100191:	e8 c9 08 00 00       	call   f0100a5f <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 f7 00 00 00    	je     f0100305 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010020e:	a8 20                	test   $0x20,%al
f0100210:	0f 85 f5 00 00 00    	jne    f010030b <kbd_proc_data+0x10b>
f0100216:	b2 60                	mov    $0x60,%dl
f0100218:	ec                   	in     (%dx),%al
f0100219:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010021b:	3c e0                	cmp    $0xe0,%al
f010021d:	75 0d                	jne    f010022c <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f010021f:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100226:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010022b:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010022c:	55                   	push   %ebp
f010022d:	89 e5                	mov    %esp,%ebp
f010022f:	53                   	push   %ebx
f0100230:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100233:	84 c0                	test   %al,%al
f0100235:	79 37                	jns    f010026e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100237:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010023d:	89 cb                	mov    %ecx,%ebx
f010023f:	83 e3 40             	and    $0x40,%ebx
f0100242:	83 e0 7f             	and    $0x7f,%eax
f0100245:	85 db                	test   %ebx,%ebx
f0100247:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010024a:	0f b6 d2             	movzbl %dl,%edx
f010024d:	0f b6 82 40 1c 10 f0 	movzbl -0xfefe3c0(%edx),%eax
f0100254:	83 c8 40             	or     $0x40,%eax
f0100257:	0f b6 c0             	movzbl %al,%eax
f010025a:	f7 d0                	not    %eax
f010025c:	21 c1                	and    %eax,%ecx
f010025e:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f0100264:	b8 00 00 00 00       	mov    $0x0,%eax
f0100269:	e9 a3 00 00 00       	jmp    f0100311 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010026e:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100274:	f6 c1 40             	test   $0x40,%cl
f0100277:	74 0e                	je     f0100287 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100279:	83 c8 80             	or     $0xffffff80,%eax
f010027c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010027e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100281:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100287:	0f b6 d2             	movzbl %dl,%edx
f010028a:	0f b6 82 40 1c 10 f0 	movzbl -0xfefe3c0(%edx),%eax
f0100291:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f0100297:	0f b6 8a 40 1b 10 f0 	movzbl -0xfefe4c0(%edx),%ecx
f010029e:	31 c8                	xor    %ecx,%eax
f01002a0:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002a5:	89 c1                	mov    %eax,%ecx
f01002a7:	83 e1 03             	and    $0x3,%ecx
f01002aa:	8b 0c 8d 20 1b 10 f0 	mov    -0xfefe4e0(,%ecx,4),%ecx
f01002b1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002b5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b8:	a8 08                	test   $0x8,%al
f01002ba:	74 1b                	je     f01002d7 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f01002bc:	89 da                	mov    %ebx,%edx
f01002be:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002c1:	83 f9 19             	cmp    $0x19,%ecx
f01002c4:	77 05                	ja     f01002cb <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f01002c6:	83 eb 20             	sub    $0x20,%ebx
f01002c9:	eb 0c                	jmp    f01002d7 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f01002cb:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002ce:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002d1:	83 fa 19             	cmp    $0x19,%edx
f01002d4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d7:	f7 d0                	not    %eax
f01002d9:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002dd:	f6 c2 06             	test   $0x6,%dl
f01002e0:	75 2f                	jne    f0100311 <kbd_proc_data+0x111>
f01002e2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e8:	75 27                	jne    f0100311 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f01002ea:	c7 04 24 e4 1a 10 f0 	movl   $0xf0101ae4,(%esp)
f01002f1:	e8 69 07 00 00       	call   f0100a5f <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f6:	ba 92 00 00 00       	mov    $0x92,%edx
f01002fb:	b8 03 00 00 00       	mov    $0x3,%eax
f0100300:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100301:	89 d8                	mov    %ebx,%eax
f0100303:	eb 0c                	jmp    f0100311 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100305:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010030a:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010030b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100310:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100311:	83 c4 14             	add    $0x14,%esp
f0100314:	5b                   	pop    %ebx
f0100315:	5d                   	pop    %ebp
f0100316:	c3                   	ret    

f0100317 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100317:	55                   	push   %ebp
f0100318:	89 e5                	mov    %esp,%ebp
f010031a:	57                   	push   %edi
f010031b:	56                   	push   %esi
f010031c:	53                   	push   %ebx
f010031d:	83 ec 1c             	sub    $0x1c,%esp
f0100320:	89 c7                	mov    %eax,%edi
f0100322:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100327:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100331:	eb 06                	jmp    f0100339 <cons_putc+0x22>
f0100333:	89 ca                	mov    %ecx,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	89 f2                	mov    %esi,%edx
f010033b:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010033c:	a8 20                	test   $0x20,%al
f010033e:	75 05                	jne    f0100345 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100340:	83 eb 01             	sub    $0x1,%ebx
f0100343:	75 ee                	jne    f0100333 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100345:	89 f8                	mov    %edi,%eax
f0100347:	0f b6 c0             	movzbl %al,%eax
f010034a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100352:	ee                   	out    %al,(%dx)
f0100353:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100358:	be 79 03 00 00       	mov    $0x379,%esi
f010035d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100362:	eb 06                	jmp    f010036a <cons_putc+0x53>
f0100364:	89 ca                	mov    %ecx,%edx
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	ec                   	in     (%dx),%al
f010036a:	89 f2                	mov    %esi,%edx
f010036c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010036d:	84 c0                	test   %al,%al
f010036f:	78 05                	js     f0100376 <cons_putc+0x5f>
f0100371:	83 eb 01             	sub    $0x1,%ebx
f0100374:	75 ee                	jne    f0100364 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100376:	ba 78 03 00 00       	mov    $0x378,%edx
f010037b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037f:	ee                   	out    %al,(%dx)
f0100380:	b2 7a                	mov    $0x7a,%dl
f0100382:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100387:	ee                   	out    %al,(%dx)
f0100388:	b8 08 00 00 00       	mov    $0x8,%eax
f010038d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038e:	89 fa                	mov    %edi,%edx
f0100390:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100396:	89 f8                	mov    %edi,%eax
f0100398:	80 cc 07             	or     $0x7,%ah
f010039b:	85 d2                	test   %edx,%edx
f010039d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003a0:	89 f8                	mov    %edi,%eax
f01003a2:	0f b6 c0             	movzbl %al,%eax
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	74 78                	je     f0100422 <cons_putc+0x10b>
f01003aa:	83 f8 09             	cmp    $0x9,%eax
f01003ad:	7f 0a                	jg     f01003b9 <cons_putc+0xa2>
f01003af:	83 f8 08             	cmp    $0x8,%eax
f01003b2:	74 18                	je     f01003cc <cons_putc+0xb5>
f01003b4:	e9 9d 00 00 00       	jmp    f0100456 <cons_putc+0x13f>
f01003b9:	83 f8 0a             	cmp    $0xa,%eax
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xe5>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xed>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f01003cc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1aa>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100403:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 eb fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 e1 fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 d7 fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 cd fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 c3 fe ff ff       	call   f0100317 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 76 11 00 00       	call   f0101614 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004c0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100535:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010053a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010054b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100643:	89 f2                	mov    %esi,%edx
f0100645:	ec                   	in     (%dx),%al
f0100646:	89 da                	mov    %ebx,%edx
f0100648:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100649:	84 c9                	test   %cl,%cl
f010064b:	75 0c                	jne    f0100659 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010064d:	c7 04 24 f0 1a 10 f0 	movl   $0xf0101af0,(%esp)
f0100654:	e8 06 04 00 00       	call   f0100a5f <cprintf>
}
f0100659:	83 c4 1c             	add    $0x1c,%esp
f010065c:	5b                   	pop    %ebx
f010065d:	5e                   	pop    %esi
f010065e:	5f                   	pop    %edi
f010065f:	5d                   	pop    %ebp
f0100660:	c3                   	ret    

f0100661 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100667:	8b 45 08             	mov    0x8(%ebp),%eax
f010066a:	e8 a8 fc ff ff       	call   f0100317 <cons_putc>
}
f010066f:	c9                   	leave  
f0100670:	c3                   	ret    

f0100671 <getchar>:

int
getchar(void)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100677:	e8 a9 fe ff ff       	call   f0100525 <cons_getc>
f010067c:	85 c0                	test   %eax,%eax
f010067e:	74 f7                	je     f0100677 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <iscons>:

int
iscons(int fdnum)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100685:	b8 01 00 00 00       	mov    $0x1,%eax
f010068a:	5d                   	pop    %ebp
f010068b:	c3                   	ret    
f010068c:	66 90                	xchg   %ax,%ax
f010068e:	66 90                	xchg   %ax,%ax

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 40 1d 10 	movl   $0xf0101d40,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 5e 1d 10 	movl   $0xf0101d5e,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 63 1d 10 f0 	movl   $0xf0101d63,(%esp)
f01006ad:	e8 ad 03 00 00       	call   f0100a5f <cprintf>
f01006b2:	c7 44 24 08 30 1e 10 	movl   $0xf0101e30,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 6c 1d 10 	movl   $0xf0101d6c,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 63 1d 10 f0 	movl   $0xf0101d63,(%esp)
f01006c9:	e8 91 03 00 00       	call   f0100a5f <cprintf>
f01006ce:	c7 44 24 08 75 1d 10 	movl   $0xf0101d75,0x8(%esp)
f01006d5:	f0 
f01006d6:	c7 44 24 04 8c 1d 10 	movl   $0xf0101d8c,0x4(%esp)
f01006dd:	f0 
f01006de:	c7 04 24 63 1d 10 f0 	movl   $0xf0101d63,(%esp)
f01006e5:	e8 75 03 00 00       	call   f0100a5f <cprintf>
	return 0;
}
f01006ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ef:	c9                   	leave  
f01006f0:	c3                   	ret    

f01006f1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006f1:	55                   	push   %ebp
f01006f2:	89 e5                	mov    %esp,%ebp
f01006f4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f7:	c7 04 24 96 1d 10 f0 	movl   $0xf0101d96,(%esp)
f01006fe:	e8 5c 03 00 00       	call   f0100a5f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100703:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010070a:	00 
f010070b:	c7 04 24 58 1e 10 f0 	movl   $0xf0101e58,(%esp)
f0100712:	e8 48 03 00 00       	call   f0100a5f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100717:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 80 1e 10 f0 	movl   $0xf0101e80,(%esp)
f010072e:	e8 2c 03 00 00       	call   f0100a5f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100733:	c7 44 24 08 57 1a 10 	movl   $0x101a57,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 57 1a 10 	movl   $0xf0101a57,0x4(%esp)
f0100742:	f0 
f0100743:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f010074a:	e8 10 03 00 00       	call   f0100a5f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010074f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100756:	00 
f0100757:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010075e:	f0 
f010075f:	c7 04 24 c8 1e 10 f0 	movl   $0xf0101ec8,(%esp)
f0100766:	e8 f4 02 00 00       	call   f0100a5f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010076b:	c7 44 24 08 40 29 11 	movl   $0x112940,0x8(%esp)
f0100772:	00 
f0100773:	c7 44 24 04 40 29 11 	movl   $0xf0112940,0x4(%esp)
f010077a:	f0 
f010077b:	c7 04 24 ec 1e 10 f0 	movl   $0xf0101eec,(%esp)
f0100782:	e8 d8 02 00 00       	call   f0100a5f <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100787:	b8 3f 2d 11 f0       	mov    $0xf0112d3f,%eax
f010078c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100791:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100796:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010079c:	85 c0                	test   %eax,%eax
f010079e:	0f 48 c2             	cmovs  %edx,%eax
f01007a1:	c1 f8 0a             	sar    $0xa,%eax
f01007a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a8:	c7 04 24 10 1f 10 f0 	movl   $0xf0101f10,(%esp)
f01007af:	e8 ab 02 00 00       	call   f0100a5f <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b9:	c9                   	leave  
f01007ba:	c3                   	ret    

f01007bb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007bb:	55                   	push   %ebp
f01007bc:	89 e5                	mov    %esp,%ebp
f01007be:	57                   	push   %edi
f01007bf:	56                   	push   %esi
f01007c0:	53                   	push   %ebx
f01007c1:	83 ec 6c             	sub    $0x6c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01007c4:	89 e8                	mov    %ebp,%eax
f01007c6:	89 c3                	mov    %eax,%ebx
	// Your code here.
	uint32_t ebp,eip,arg[5];
	uint32_t  *ptr_ebp;//tianjia

	ebp = read_ebp();
	eip = *((uint32_t*)ebp+1);
f01007c8:	8b 70 04             	mov    0x4(%eax),%esi
f01007cb:	89 75 c4             	mov    %esi,-0x3c(%ebp)
	struct Eipdebuginfo info;
	arg[0] = *((uint32_t*)ebp+2);
f01007ce:	8b 78 08             	mov    0x8(%eax),%edi
f01007d1:	89 7d c0             	mov    %edi,-0x40(%ebp)

	arg[1] = *((uint32_t*)ebp+3);
f01007d4:	8b 70 0c             	mov    0xc(%eax),%esi
f01007d7:	89 75 bc             	mov    %esi,-0x44(%ebp)

	arg[2] = *((uint32_t*)ebp+4);
f01007da:	8b 78 10             	mov    0x10(%eax),%edi
f01007dd:	89 7d b8             	mov    %edi,-0x48(%ebp)

	arg[3] = *((uint32_t*)ebp+5);
f01007e0:	8b 78 14             	mov    0x14(%eax),%edi

	arg[4] = *((uint32_t*)ebp+6);
f01007e3:	8b 70 18             	mov    0x18(%eax),%esi
	cprintf("Stack backtrace:\n");
f01007e6:	c7 04 24 af 1d 10 f0 	movl   $0xf0101daf,(%esp)
f01007ed:	e8 6d 02 00 00       	call   f0100a5f <cprintf>
	while(ebp != 0x00)
f01007f2:	e9 a4 00 00 00       	jmp    f010089b <mon_backtrace+0xe0>
	{
	ptr_ebp=(uint32_t *)ebp;
f01007f7:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
	cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",
f01007fa:	89 74 24 1c          	mov    %esi,0x1c(%esp)
f01007fe:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0100802:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0100805:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100809:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010080c:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100810:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100813:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100817:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010081a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010081e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100822:	c7 04 24 3c 1f 10 f0 	movl   $0xf0101f3c,(%esp)
f0100829:	e8 31 02 00 00       	call   f0100a5f <cprintf>
	ebp,eip,arg[0],arg[1],arg[2],arg[3],arg[4]);
	ebp = *(uint32_t *)ebp;
f010082e:	8b 03                	mov    (%ebx),%eax
	eip = *((uint32_t*)ebp+1);
f0100830:	8b 50 04             	mov    0x4(%eax),%edx
f0100833:	89 55 c4             	mov    %edx,-0x3c(%ebp)
	arg[0] = *((uint32_t*)ebp+2);
f0100836:	8b 48 08             	mov    0x8(%eax),%ecx
f0100839:	89 4d c0             	mov    %ecx,-0x40(%ebp)

	arg[1] = *((uint32_t*)ebp+3);
f010083c:	8b 50 0c             	mov    0xc(%eax),%edx
f010083f:	89 55 bc             	mov    %edx,-0x44(%ebp)

	arg[2] = *((uint32_t*)ebp+4);
f0100842:	8b 48 10             	mov    0x10(%eax),%ecx
f0100845:	89 4d b8             	mov    %ecx,-0x48(%ebp)

	arg[3] = *((uint32_t*)ebp+5);
f0100848:	8b 78 14             	mov    0x14(%eax),%edi

	arg[4] = *((uint32_t*)ebp+6);
f010084b:	8b 70 18             	mov    0x18(%eax),%esi
	if (debuginfo_eip(ptr_ebp[1], &info) == 0) {
f010084e:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100851:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100855:	8b 43 04             	mov    0x4(%ebx),%eax
f0100858:	89 04 24             	mov    %eax,(%esp)
f010085b:	e8 f6 02 00 00       	call   f0100b56 <debuginfo_eip>
f0100860:	85 c0                	test   %eax,%eax
f0100862:	75 32                	jne    f0100896 <mon_backtrace+0xdb>
            uint32_t fn_offset = ptr_ebp[1] - info.eip_fn_addr;
f0100864:	8b 43 04             	mov    0x4(%ebx),%eax
f0100867:	2b 45 e0             	sub    -0x20(%ebp),%eax
            cprintf("\t\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line,info.eip_fn_namelen,  info.eip_fn_name, fn_offset);
f010086a:	89 44 24 14          	mov    %eax,0x14(%esp)
f010086e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100871:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100875:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100878:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010087c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010087f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100883:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100886:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088a:	c7 04 24 c1 1d 10 f0 	movl   $0xf0101dc1,(%esp)
f0100891:	e8 c9 01 00 00       	call   f0100a5f <cprintf>
        }
        ebp = *ptr_ebp;
f0100896:	8b 45 b4             	mov    -0x4c(%ebp),%eax
f0100899:	8b 18                	mov    (%eax),%ebx

	arg[3] = *((uint32_t*)ebp+5);

	arg[4] = *((uint32_t*)ebp+6);
	cprintf("Stack backtrace:\n");
	while(ebp != 0x00)
f010089b:	85 db                	test   %ebx,%ebx
f010089d:	0f 85 54 ff ff ff    	jne    f01007f7 <mon_backtrace+0x3c>
        ebp = *ptr_ebp;
	}

	return 0;
	
}
f01008a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01008a8:	83 c4 6c             	add    $0x6c,%esp
f01008ab:	5b                   	pop    %ebx
f01008ac:	5e                   	pop    %esi
f01008ad:	5f                   	pop    %edi
f01008ae:	5d                   	pop    %ebp
f01008af:	c3                   	ret    

f01008b0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008b0:	55                   	push   %ebp
f01008b1:	89 e5                	mov    %esp,%ebp
f01008b3:	57                   	push   %edi
f01008b4:	56                   	push   %esi
f01008b5:	53                   	push   %ebx
f01008b6:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;
	unsigned int i=0x00646c72;
f01008b9:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
	cprintf("Welcome to the JOS kernel monitor!\n");
f01008c0:	c7 04 24 70 1f 10 f0 	movl   $0xf0101f70,(%esp)
f01008c7:	e8 93 01 00 00       	call   f0100a5f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008cc:	c7 04 24 94 1f 10 f0 	movl   $0xf0101f94,(%esp)
f01008d3:	e8 87 01 00 00       	call   f0100a5f <cprintf>
	cprintf("\033[0;32;40m H%x Wo%s\n",57616,&i);
f01008d8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01008db:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008df:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f01008e6:	00 
f01008e7:	c7 04 24 d3 1d 10 f0 	movl   $0xf0101dd3,(%esp)
f01008ee:	e8 6c 01 00 00       	call   f0100a5f <cprintf>
	cprintf("x=%d y=%d\n",3);
f01008f3:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01008fa:	00 
f01008fb:	c7 04 24 e8 1d 10 f0 	movl   $0xf0101de8,(%esp)
f0100902:	e8 58 01 00 00       	call   f0100a5f <cprintf>
	while (1) {
		buf = readline("K> ");
f0100907:	c7 04 24 f3 1d 10 f0 	movl   $0xf0101df3,(%esp)
f010090e:	e8 5d 0a 00 00       	call   f0101370 <readline>
f0100913:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100915:	85 c0                	test   %eax,%eax
f0100917:	74 ee                	je     f0100907 <monitor+0x57>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100919:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100920:	be 00 00 00 00       	mov    $0x0,%esi
f0100925:	eb 0a                	jmp    f0100931 <monitor+0x81>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100927:	c6 03 00             	movb   $0x0,(%ebx)
f010092a:	89 f7                	mov    %esi,%edi
f010092c:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010092f:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100931:	0f b6 03             	movzbl (%ebx),%eax
f0100934:	84 c0                	test   %al,%al
f0100936:	74 63                	je     f010099b <monitor+0xeb>
f0100938:	0f be c0             	movsbl %al,%eax
f010093b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093f:	c7 04 24 f7 1d 10 f0 	movl   $0xf0101df7,(%esp)
f0100946:	e8 3f 0c 00 00       	call   f010158a <strchr>
f010094b:	85 c0                	test   %eax,%eax
f010094d:	75 d8                	jne    f0100927 <monitor+0x77>
			*buf++ = 0;
		if (*buf == 0)
f010094f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100952:	74 47                	je     f010099b <monitor+0xeb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100954:	83 fe 0f             	cmp    $0xf,%esi
f0100957:	75 16                	jne    f010096f <monitor+0xbf>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100959:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100960:	00 
f0100961:	c7 04 24 fc 1d 10 f0 	movl   $0xf0101dfc,(%esp)
f0100968:	e8 f2 00 00 00       	call   f0100a5f <cprintf>
f010096d:	eb 98                	jmp    f0100907 <monitor+0x57>
			return 0;
		}
		argv[argc++] = buf;
f010096f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100972:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f0100976:	eb 03                	jmp    f010097b <monitor+0xcb>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100978:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010097b:	0f b6 03             	movzbl (%ebx),%eax
f010097e:	84 c0                	test   %al,%al
f0100980:	74 ad                	je     f010092f <monitor+0x7f>
f0100982:	0f be c0             	movsbl %al,%eax
f0100985:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100989:	c7 04 24 f7 1d 10 f0 	movl   $0xf0101df7,(%esp)
f0100990:	e8 f5 0b 00 00       	call   f010158a <strchr>
f0100995:	85 c0                	test   %eax,%eax
f0100997:	74 df                	je     f0100978 <monitor+0xc8>
f0100999:	eb 94                	jmp    f010092f <monitor+0x7f>
			buf++;
	}
	argv[argc] = 0;
f010099b:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f01009a2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009a3:	85 f6                	test   %esi,%esi
f01009a5:	0f 84 5c ff ff ff    	je     f0100907 <monitor+0x57>
f01009ab:	bb 00 00 00 00       	mov    $0x0,%ebx
f01009b0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009b3:	8b 04 85 c0 1f 10 f0 	mov    -0xfefe040(,%eax,4),%eax
f01009ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009be:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009c1:	89 04 24             	mov    %eax,(%esp)
f01009c4:	e8 63 0b 00 00       	call   f010152c <strcmp>
f01009c9:	85 c0                	test   %eax,%eax
f01009cb:	75 24                	jne    f01009f1 <monitor+0x141>
			return commands[i].func(argc, argv, tf);
f01009cd:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009d0:	8b 55 08             	mov    0x8(%ebp),%edx
f01009d3:	89 54 24 08          	mov    %edx,0x8(%esp)
f01009d7:	8d 4d a4             	lea    -0x5c(%ebp),%ecx
f01009da:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01009de:	89 34 24             	mov    %esi,(%esp)
f01009e1:	ff 14 85 c8 1f 10 f0 	call   *-0xfefe038(,%eax,4)
	cprintf("\033[0;32;40m H%x Wo%s\n",57616,&i);
	cprintf("x=%d y=%d\n",3);
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009e8:	85 c0                	test   %eax,%eax
f01009ea:	78 25                	js     f0100a11 <monitor+0x161>
f01009ec:	e9 16 ff ff ff       	jmp    f0100907 <monitor+0x57>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009f1:	83 c3 01             	add    $0x1,%ebx
f01009f4:	83 fb 03             	cmp    $0x3,%ebx
f01009f7:	75 b7                	jne    f01009b0 <monitor+0x100>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009f9:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a00:	c7 04 24 19 1e 10 f0 	movl   $0xf0101e19,(%esp)
f0100a07:	e8 53 00 00 00       	call   f0100a5f <cprintf>
f0100a0c:	e9 f6 fe ff ff       	jmp    f0100907 <monitor+0x57>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a11:	83 c4 6c             	add    $0x6c,%esp
f0100a14:	5b                   	pop    %ebx
f0100a15:	5e                   	pop    %esi
f0100a16:	5f                   	pop    %edi
f0100a17:	5d                   	pop    %ebp
f0100a18:	c3                   	ret    

f0100a19 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a19:	55                   	push   %ebp
f0100a1a:	89 e5                	mov    %esp,%ebp
f0100a1c:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100a1f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a22:	89 04 24             	mov    %eax,(%esp)
f0100a25:	e8 37 fc ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100a2a:	c9                   	leave  
f0100a2b:	c3                   	ret    

f0100a2c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a2c:	55                   	push   %ebp
f0100a2d:	89 e5                	mov    %esp,%ebp
f0100a2f:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a32:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a39:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a3c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a40:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a43:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a47:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a4a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a4e:	c7 04 24 19 0a 10 f0 	movl   $0xf0100a19,(%esp)
f0100a55:	e8 b4 04 00 00       	call   f0100f0e <vprintfmt>
	return cnt;
}
f0100a5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a5d:	c9                   	leave  
f0100a5e:	c3                   	ret    

f0100a5f <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a5f:	55                   	push   %ebp
f0100a60:	89 e5                	mov    %esp,%ebp
f0100a62:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a65:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a68:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a6c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a6f:	89 04 24             	mov    %eax,(%esp)
f0100a72:	e8 b5 ff ff ff       	call   f0100a2c <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a77:	c9                   	leave  
f0100a78:	c3                   	ret    

f0100a79 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a79:	55                   	push   %ebp
f0100a7a:	89 e5                	mov    %esp,%ebp
f0100a7c:	57                   	push   %edi
f0100a7d:	56                   	push   %esi
f0100a7e:	53                   	push   %ebx
f0100a7f:	83 ec 10             	sub    $0x10,%esp
f0100a82:	89 c6                	mov    %eax,%esi
f0100a84:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a87:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a8a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a8d:	8b 1a                	mov    (%edx),%ebx
f0100a8f:	8b 01                	mov    (%ecx),%eax
f0100a91:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a94:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a9b:	eb 77                	jmp    f0100b14 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100aa0:	01 d8                	add    %ebx,%eax
f0100aa2:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100aa7:	99                   	cltd   
f0100aa8:	f7 f9                	idiv   %ecx
f0100aaa:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aac:	eb 01                	jmp    f0100aaf <stab_binsearch+0x36>
			m--;
f0100aae:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aaf:	39 d9                	cmp    %ebx,%ecx
f0100ab1:	7c 1d                	jl     f0100ad0 <stab_binsearch+0x57>
f0100ab3:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100ab6:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100abb:	39 fa                	cmp    %edi,%edx
f0100abd:	75 ef                	jne    f0100aae <stab_binsearch+0x35>
f0100abf:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100ac2:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100ac5:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100ac9:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100acc:	73 18                	jae    f0100ae6 <stab_binsearch+0x6d>
f0100ace:	eb 05                	jmp    f0100ad5 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ad0:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100ad3:	eb 3f                	jmp    f0100b14 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ad5:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100ad8:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100ada:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100add:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100ae4:	eb 2e                	jmp    f0100b14 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100ae6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100ae9:	73 15                	jae    f0100b00 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100aeb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100aee:	48                   	dec    %eax
f0100aef:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100af2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100af5:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100af7:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100afe:	eb 14                	jmp    f0100b14 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b00:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100b03:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100b06:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100b08:	ff 45 0c             	incl   0xc(%ebp)
f0100b0b:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b0d:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b14:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100b17:	7e 84                	jle    f0100a9d <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b19:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100b1d:	75 0d                	jne    f0100b2c <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100b1f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100b22:	8b 00                	mov    (%eax),%eax
f0100b24:	48                   	dec    %eax
f0100b25:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b28:	89 07                	mov    %eax,(%edi)
f0100b2a:	eb 22                	jmp    f0100b4e <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b2c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b2f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b31:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100b34:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b36:	eb 01                	jmp    f0100b39 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b38:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b39:	39 c1                	cmp    %eax,%ecx
f0100b3b:	7d 0c                	jge    f0100b49 <stab_binsearch+0xd0>
f0100b3d:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100b40:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100b45:	39 fa                	cmp    %edi,%edx
f0100b47:	75 ef                	jne    f0100b38 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b49:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100b4c:	89 07                	mov    %eax,(%edi)
	}
}
f0100b4e:	83 c4 10             	add    $0x10,%esp
f0100b51:	5b                   	pop    %ebx
f0100b52:	5e                   	pop    %esi
f0100b53:	5f                   	pop    %edi
f0100b54:	5d                   	pop    %ebp
f0100b55:	c3                   	ret    

f0100b56 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b56:	55                   	push   %ebp
f0100b57:	89 e5                	mov    %esp,%ebp
f0100b59:	57                   	push   %edi
f0100b5a:	56                   	push   %esi
f0100b5b:	53                   	push   %ebx
f0100b5c:	83 ec 3c             	sub    $0x3c,%esp
f0100b5f:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b62:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b65:	c7 03 e4 1f 10 f0    	movl   $0xf0101fe4,(%ebx)
	info->eip_line = 0;
f0100b6b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b72:	c7 43 08 e4 1f 10 f0 	movl   $0xf0101fe4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b79:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b80:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b83:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b8a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b90:	76 12                	jbe    f0100ba4 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b92:	b8 50 75 10 f0       	mov    $0xf0107550,%eax
f0100b97:	3d 49 5c 10 f0       	cmp    $0xf0105c49,%eax
f0100b9c:	0f 86 cd 01 00 00    	jbe    f0100d6f <debuginfo_eip+0x219>
f0100ba2:	eb 1c                	jmp    f0100bc0 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ba4:	c7 44 24 08 ee 1f 10 	movl   $0xf0101fee,0x8(%esp)
f0100bab:	f0 
f0100bac:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100bb3:	00 
f0100bb4:	c7 04 24 fb 1f 10 f0 	movl   $0xf0101ffb,(%esp)
f0100bbb:	e8 38 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bc0:	80 3d 4f 75 10 f0 00 	cmpb   $0x0,0xf010754f
f0100bc7:	0f 85 a9 01 00 00    	jne    f0100d76 <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bcd:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bd4:	b8 48 5c 10 f0       	mov    $0xf0105c48,%eax
f0100bd9:	2d 1c 22 10 f0       	sub    $0xf010221c,%eax
f0100bde:	c1 f8 02             	sar    $0x2,%eax
f0100be1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100be7:	83 e8 01             	sub    $0x1,%eax
f0100bea:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bed:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bf1:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100bf8:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bfb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bfe:	b8 1c 22 10 f0       	mov    $0xf010221c,%eax
f0100c03:	e8 71 fe ff ff       	call   f0100a79 <stab_binsearch>
	if (lfile == 0)
f0100c08:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c0b:	85 c0                	test   %eax,%eax
f0100c0d:	0f 84 6a 01 00 00    	je     f0100d7d <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c13:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c16:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c19:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c1c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c20:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c27:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c2a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c2d:	b8 1c 22 10 f0       	mov    $0xf010221c,%eax
f0100c32:	e8 42 fe ff ff       	call   f0100a79 <stab_binsearch>

	if (lfun <= rfun) {
f0100c37:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c3a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c3d:	39 d0                	cmp    %edx,%eax
f0100c3f:	7f 3d                	jg     f0100c7e <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c41:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100c44:	8d b9 1c 22 10 f0    	lea    -0xfefdde4(%ecx),%edi
f0100c4a:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100c4d:	8b 89 1c 22 10 f0    	mov    -0xfefdde4(%ecx),%ecx
f0100c53:	bf 50 75 10 f0       	mov    $0xf0107550,%edi
f0100c58:	81 ef 49 5c 10 f0    	sub    $0xf0105c49,%edi
f0100c5e:	39 f9                	cmp    %edi,%ecx
f0100c60:	73 09                	jae    f0100c6b <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c62:	81 c1 49 5c 10 f0    	add    $0xf0105c49,%ecx
f0100c68:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c6b:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c6e:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c71:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c74:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c76:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c79:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c7c:	eb 0f                	jmp    f0100c8d <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c7e:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c81:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c84:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c87:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c8a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c8d:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c94:	00 
f0100c95:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c98:	89 04 24             	mov    %eax,(%esp)
f0100c9b:	e8 0b 09 00 00       	call   f01015ab <strfind>
f0100ca0:	2b 43 08             	sub    0x8(%ebx),%eax
f0100ca3:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100ca6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100caa:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100cb1:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100cb4:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100cb7:	b8 1c 22 10 f0       	mov    $0xf010221c,%eax
f0100cbc:	e8 b8 fd ff ff       	call   f0100a79 <stab_binsearch>
   	 if (lline <= rline) {
f0100cc1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cc4:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100cc7:	0f 8f b7 00 00 00    	jg     f0100d84 <debuginfo_eip+0x22e>
    	    info->eip_line = stabs[lline].n_desc;
f0100ccd:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cd0:	0f b7 80 22 22 10 f0 	movzwl -0xfefddde(%eax),%eax
f0100cd7:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100cda:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cdd:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100ce0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ce3:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100ce6:	81 c2 1c 22 10 f0    	add    $0xf010221c,%edx
f0100cec:	eb 06                	jmp    f0100cf4 <debuginfo_eip+0x19e>
f0100cee:	83 e8 01             	sub    $0x1,%eax
f0100cf1:	83 ea 0c             	sub    $0xc,%edx
f0100cf4:	89 c6                	mov    %eax,%esi
f0100cf6:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100cf9:	7f 33                	jg     f0100d2e <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0100cfb:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100cff:	80 f9 84             	cmp    $0x84,%cl
f0100d02:	74 0b                	je     f0100d0f <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d04:	80 f9 64             	cmp    $0x64,%cl
f0100d07:	75 e5                	jne    f0100cee <debuginfo_eip+0x198>
f0100d09:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100d0d:	74 df                	je     f0100cee <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d0f:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100d12:	8b 86 1c 22 10 f0    	mov    -0xfefdde4(%esi),%eax
f0100d18:	ba 50 75 10 f0       	mov    $0xf0107550,%edx
f0100d1d:	81 ea 49 5c 10 f0    	sub    $0xf0105c49,%edx
f0100d23:	39 d0                	cmp    %edx,%eax
f0100d25:	73 07                	jae    f0100d2e <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d27:	05 49 5c 10 f0       	add    $0xf0105c49,%eax
f0100d2c:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d2e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d31:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d34:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d39:	39 ca                	cmp    %ecx,%edx
f0100d3b:	7d 53                	jge    f0100d90 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0100d3d:	8d 42 01             	lea    0x1(%edx),%eax
f0100d40:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d43:	89 c2                	mov    %eax,%edx
f0100d45:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d48:	05 1c 22 10 f0       	add    $0xf010221c,%eax
f0100d4d:	89 ce                	mov    %ecx,%esi
f0100d4f:	eb 04                	jmp    f0100d55 <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d51:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d55:	39 d6                	cmp    %edx,%esi
f0100d57:	7e 32                	jle    f0100d8b <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d59:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100d5d:	83 c2 01             	add    $0x1,%edx
f0100d60:	83 c0 0c             	add    $0xc,%eax
f0100d63:	80 f9 a0             	cmp    $0xa0,%cl
f0100d66:	74 e9                	je     f0100d51 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d68:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d6d:	eb 21                	jmp    f0100d90 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d74:	eb 1a                	jmp    f0100d90 <debuginfo_eip+0x23a>
f0100d76:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d7b:	eb 13                	jmp    f0100d90 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d82:	eb 0c                	jmp    f0100d90 <debuginfo_eip+0x23a>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
   	 if (lline <= rline) {
    	    info->eip_line = stabs[lline].n_desc;
    	} else {
        return -1;
f0100d84:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d89:	eb 05                	jmp    f0100d90 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d90:	83 c4 3c             	add    $0x3c,%esp
f0100d93:	5b                   	pop    %ebx
f0100d94:	5e                   	pop    %esi
f0100d95:	5f                   	pop    %edi
f0100d96:	5d                   	pop    %ebp
f0100d97:	c3                   	ret    
f0100d98:	66 90                	xchg   %ax,%ax
f0100d9a:	66 90                	xchg   %ax,%ax
f0100d9c:	66 90                	xchg   %ax,%ax
f0100d9e:	66 90                	xchg   %ax,%ax

f0100da0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100da0:	55                   	push   %ebp
f0100da1:	89 e5                	mov    %esp,%ebp
f0100da3:	57                   	push   %edi
f0100da4:	56                   	push   %esi
f0100da5:	53                   	push   %ebx
f0100da6:	83 ec 3c             	sub    $0x3c,%esp
f0100da9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dac:	89 d7                	mov    %edx,%edi
f0100dae:	8b 45 08             	mov    0x8(%ebp),%eax
f0100db1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100db4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100db7:	89 c3                	mov    %eax,%ebx
f0100db9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100dbc:	8b 45 10             	mov    0x10(%ebp),%eax
f0100dbf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100dc2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100dc7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100dca:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100dcd:	39 d9                	cmp    %ebx,%ecx
f0100dcf:	72 05                	jb     f0100dd6 <printnum+0x36>
f0100dd1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100dd4:	77 69                	ja     f0100e3f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dd6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100dd9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100ddd:	83 ee 01             	sub    $0x1,%esi
f0100de0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100de4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100de8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100dec:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100df0:	89 c3                	mov    %eax,%ebx
f0100df2:	89 d6                	mov    %edx,%esi
f0100df4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100df7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100dfa:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100dfe:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100e02:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e05:	89 04 24             	mov    %eax,(%esp)
f0100e08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e0b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e0f:	e8 bc 09 00 00       	call   f01017d0 <__udivdi3>
f0100e14:	89 d9                	mov    %ebx,%ecx
f0100e16:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100e1a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100e1e:	89 04 24             	mov    %eax,(%esp)
f0100e21:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e25:	89 fa                	mov    %edi,%edx
f0100e27:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e2a:	e8 71 ff ff ff       	call   f0100da0 <printnum>
f0100e2f:	eb 1b                	jmp    f0100e4c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e31:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e35:	8b 45 18             	mov    0x18(%ebp),%eax
f0100e38:	89 04 24             	mov    %eax,(%esp)
f0100e3b:	ff d3                	call   *%ebx
f0100e3d:	eb 03                	jmp    f0100e42 <printnum+0xa2>
f0100e3f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e42:	83 ee 01             	sub    $0x1,%esi
f0100e45:	85 f6                	test   %esi,%esi
f0100e47:	7f e8                	jg     f0100e31 <printnum+0x91>
f0100e49:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e4c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e50:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e54:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100e57:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e5a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e5e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e62:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e65:	89 04 24             	mov    %eax,(%esp)
f0100e68:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e6b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e6f:	e8 8c 0a 00 00       	call   f0101900 <__umoddi3>
f0100e74:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e78:	0f be 80 09 20 10 f0 	movsbl -0xfefdff7(%eax),%eax
f0100e7f:	89 04 24             	mov    %eax,(%esp)
f0100e82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e85:	ff d0                	call   *%eax
}
f0100e87:	83 c4 3c             	add    $0x3c,%esp
f0100e8a:	5b                   	pop    %ebx
f0100e8b:	5e                   	pop    %esi
f0100e8c:	5f                   	pop    %edi
f0100e8d:	5d                   	pop    %ebp
f0100e8e:	c3                   	ret    

f0100e8f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e8f:	55                   	push   %ebp
f0100e90:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e92:	83 fa 01             	cmp    $0x1,%edx
f0100e95:	7e 0e                	jle    f0100ea5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e97:	8b 10                	mov    (%eax),%edx
f0100e99:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e9c:	89 08                	mov    %ecx,(%eax)
f0100e9e:	8b 02                	mov    (%edx),%eax
f0100ea0:	8b 52 04             	mov    0x4(%edx),%edx
f0100ea3:	eb 22                	jmp    f0100ec7 <getuint+0x38>
	else if (lflag)
f0100ea5:	85 d2                	test   %edx,%edx
f0100ea7:	74 10                	je     f0100eb9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ea9:	8b 10                	mov    (%eax),%edx
f0100eab:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100eae:	89 08                	mov    %ecx,(%eax)
f0100eb0:	8b 02                	mov    (%edx),%eax
f0100eb2:	ba 00 00 00 00       	mov    $0x0,%edx
f0100eb7:	eb 0e                	jmp    f0100ec7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100eb9:	8b 10                	mov    (%eax),%edx
f0100ebb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ebe:	89 08                	mov    %ecx,(%eax)
f0100ec0:	8b 02                	mov    (%edx),%eax
f0100ec2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100ec7:	5d                   	pop    %ebp
f0100ec8:	c3                   	ret    

f0100ec9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ec9:	55                   	push   %ebp
f0100eca:	89 e5                	mov    %esp,%ebp
f0100ecc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ecf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ed3:	8b 10                	mov    (%eax),%edx
f0100ed5:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ed8:	73 0a                	jae    f0100ee4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100eda:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100edd:	89 08                	mov    %ecx,(%eax)
f0100edf:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ee2:	88 02                	mov    %al,(%edx)
}
f0100ee4:	5d                   	pop    %ebp
f0100ee5:	c3                   	ret    

f0100ee6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100ee6:	55                   	push   %ebp
f0100ee7:	89 e5                	mov    %esp,%ebp
f0100ee9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100eec:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100eef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ef3:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ef6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100efa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100efd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f01:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f04:	89 04 24             	mov    %eax,(%esp)
f0100f07:	e8 02 00 00 00       	call   f0100f0e <vprintfmt>
	va_end(ap);
}
f0100f0c:	c9                   	leave  
f0100f0d:	c3                   	ret    

f0100f0e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100f0e:	55                   	push   %ebp
f0100f0f:	89 e5                	mov    %esp,%ebp
f0100f11:	57                   	push   %edi
f0100f12:	56                   	push   %esi
f0100f13:	53                   	push   %ebx
f0100f14:	83 ec 3c             	sub    $0x3c,%esp
f0100f17:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100f1a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100f1d:	eb 14                	jmp    f0100f33 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100f1f:	85 c0                	test   %eax,%eax
f0100f21:	0f 84 b3 03 00 00    	je     f01012da <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100f27:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f2b:	89 04 24             	mov    %eax,(%esp)
f0100f2e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f31:	89 f3                	mov    %esi,%ebx
f0100f33:	8d 73 01             	lea    0x1(%ebx),%esi
f0100f36:	0f b6 03             	movzbl (%ebx),%eax
f0100f39:	83 f8 25             	cmp    $0x25,%eax
f0100f3c:	75 e1                	jne    f0100f1f <vprintfmt+0x11>
f0100f3e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100f42:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100f49:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100f50:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100f57:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f5c:	eb 1d                	jmp    f0100f7b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f60:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100f64:	eb 15                	jmp    f0100f7b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f66:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f68:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100f6c:	eb 0d                	jmp    f0100f7b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f6e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f71:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100f74:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f7b:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f7e:	0f b6 0e             	movzbl (%esi),%ecx
f0100f81:	0f b6 c1             	movzbl %cl,%eax
f0100f84:	83 e9 23             	sub    $0x23,%ecx
f0100f87:	80 f9 55             	cmp    $0x55,%cl
f0100f8a:	0f 87 2a 03 00 00    	ja     f01012ba <vprintfmt+0x3ac>
f0100f90:	0f b6 c9             	movzbl %cl,%ecx
f0100f93:	ff 24 8d 98 20 10 f0 	jmp    *-0xfefdf68(,%ecx,4)
f0100f9a:	89 de                	mov    %ebx,%esi
f0100f9c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100fa1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100fa4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100fa8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100fab:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100fae:	83 fb 09             	cmp    $0x9,%ebx
f0100fb1:	77 36                	ja     f0100fe9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100fb3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100fb6:	eb e9                	jmp    f0100fa1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100fb8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fbb:	8d 48 04             	lea    0x4(%eax),%ecx
f0100fbe:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100fc1:	8b 00                	mov    (%eax),%eax
f0100fc3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100fc8:	eb 22                	jmp    f0100fec <vprintfmt+0xde>
f0100fca:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100fcd:	85 c9                	test   %ecx,%ecx
f0100fcf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fd4:	0f 49 c1             	cmovns %ecx,%eax
f0100fd7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fda:	89 de                	mov    %ebx,%esi
f0100fdc:	eb 9d                	jmp    f0100f7b <vprintfmt+0x6d>
f0100fde:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fe0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100fe7:	eb 92                	jmp    f0100f7b <vprintfmt+0x6d>
f0100fe9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100fec:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100ff0:	79 89                	jns    f0100f7b <vprintfmt+0x6d>
f0100ff2:	e9 77 ff ff ff       	jmp    f0100f6e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ff7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffa:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ffc:	e9 7a ff ff ff       	jmp    f0100f7b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101001:	8b 45 14             	mov    0x14(%ebp),%eax
f0101004:	8d 50 04             	lea    0x4(%eax),%edx
f0101007:	89 55 14             	mov    %edx,0x14(%ebp)
f010100a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010100e:	8b 00                	mov    (%eax),%eax
f0101010:	89 04 24             	mov    %eax,(%esp)
f0101013:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101016:	e9 18 ff ff ff       	jmp    f0100f33 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010101b:	8b 45 14             	mov    0x14(%ebp),%eax
f010101e:	8d 50 04             	lea    0x4(%eax),%edx
f0101021:	89 55 14             	mov    %edx,0x14(%ebp)
f0101024:	8b 00                	mov    (%eax),%eax
f0101026:	99                   	cltd   
f0101027:	31 d0                	xor    %edx,%eax
f0101029:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010102b:	83 f8 06             	cmp    $0x6,%eax
f010102e:	7f 0b                	jg     f010103b <vprintfmt+0x12d>
f0101030:	8b 14 85 f0 21 10 f0 	mov    -0xfefde10(,%eax,4),%edx
f0101037:	85 d2                	test   %edx,%edx
f0101039:	75 20                	jne    f010105b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010103b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010103f:	c7 44 24 08 21 20 10 	movl   $0xf0102021,0x8(%esp)
f0101046:	f0 
f0101047:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010104b:	8b 45 08             	mov    0x8(%ebp),%eax
f010104e:	89 04 24             	mov    %eax,(%esp)
f0101051:	e8 90 fe ff ff       	call   f0100ee6 <printfmt>
f0101056:	e9 d8 fe ff ff       	jmp    f0100f33 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010105b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010105f:	c7 44 24 08 2a 20 10 	movl   $0xf010202a,0x8(%esp)
f0101066:	f0 
f0101067:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010106b:	8b 45 08             	mov    0x8(%ebp),%eax
f010106e:	89 04 24             	mov    %eax,(%esp)
f0101071:	e8 70 fe ff ff       	call   f0100ee6 <printfmt>
f0101076:	e9 b8 fe ff ff       	jmp    f0100f33 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010107b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010107e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101081:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101084:	8b 45 14             	mov    0x14(%ebp),%eax
f0101087:	8d 50 04             	lea    0x4(%eax),%edx
f010108a:	89 55 14             	mov    %edx,0x14(%ebp)
f010108d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010108f:	85 f6                	test   %esi,%esi
f0101091:	b8 1a 20 10 f0       	mov    $0xf010201a,%eax
f0101096:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0101099:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010109d:	0f 84 97 00 00 00    	je     f010113a <vprintfmt+0x22c>
f01010a3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01010a7:	0f 8e 9b 00 00 00    	jle    f0101148 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01010ad:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010b1:	89 34 24             	mov    %esi,(%esp)
f01010b4:	e8 9f 03 00 00       	call   f0101458 <strnlen>
f01010b9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01010bc:	29 c2                	sub    %eax,%edx
f01010be:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f01010c1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01010c5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01010c8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01010cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01010ce:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010d1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010d3:	eb 0f                	jmp    f01010e4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01010d5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010d9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010dc:	89 04 24             	mov    %eax,(%esp)
f01010df:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010e1:	83 eb 01             	sub    $0x1,%ebx
f01010e4:	85 db                	test   %ebx,%ebx
f01010e6:	7f ed                	jg     f01010d5 <vprintfmt+0x1c7>
f01010e8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01010eb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01010ee:	85 d2                	test   %edx,%edx
f01010f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f5:	0f 49 c2             	cmovns %edx,%eax
f01010f8:	29 c2                	sub    %eax,%edx
f01010fa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010fd:	89 d7                	mov    %edx,%edi
f01010ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101102:	eb 50                	jmp    f0101154 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101104:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101108:	74 1e                	je     f0101128 <vprintfmt+0x21a>
f010110a:	0f be d2             	movsbl %dl,%edx
f010110d:	83 ea 20             	sub    $0x20,%edx
f0101110:	83 fa 5e             	cmp    $0x5e,%edx
f0101113:	76 13                	jbe    f0101128 <vprintfmt+0x21a>
					putch('?', putdat);
f0101115:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101118:	89 44 24 04          	mov    %eax,0x4(%esp)
f010111c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101123:	ff 55 08             	call   *0x8(%ebp)
f0101126:	eb 0d                	jmp    f0101135 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0101128:	8b 55 0c             	mov    0xc(%ebp),%edx
f010112b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010112f:	89 04 24             	mov    %eax,(%esp)
f0101132:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101135:	83 ef 01             	sub    $0x1,%edi
f0101138:	eb 1a                	jmp    f0101154 <vprintfmt+0x246>
f010113a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010113d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101140:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101143:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101146:	eb 0c                	jmp    f0101154 <vprintfmt+0x246>
f0101148:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010114b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010114e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101151:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101154:	83 c6 01             	add    $0x1,%esi
f0101157:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010115b:	0f be c2             	movsbl %dl,%eax
f010115e:	85 c0                	test   %eax,%eax
f0101160:	74 27                	je     f0101189 <vprintfmt+0x27b>
f0101162:	85 db                	test   %ebx,%ebx
f0101164:	78 9e                	js     f0101104 <vprintfmt+0x1f6>
f0101166:	83 eb 01             	sub    $0x1,%ebx
f0101169:	79 99                	jns    f0101104 <vprintfmt+0x1f6>
f010116b:	89 f8                	mov    %edi,%eax
f010116d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101170:	8b 75 08             	mov    0x8(%ebp),%esi
f0101173:	89 c3                	mov    %eax,%ebx
f0101175:	eb 1a                	jmp    f0101191 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101177:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010117b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101182:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101184:	83 eb 01             	sub    $0x1,%ebx
f0101187:	eb 08                	jmp    f0101191 <vprintfmt+0x283>
f0101189:	89 fb                	mov    %edi,%ebx
f010118b:	8b 75 08             	mov    0x8(%ebp),%esi
f010118e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101191:	85 db                	test   %ebx,%ebx
f0101193:	7f e2                	jg     f0101177 <vprintfmt+0x269>
f0101195:	89 75 08             	mov    %esi,0x8(%ebp)
f0101198:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010119b:	e9 93 fd ff ff       	jmp    f0100f33 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011a0:	83 fa 01             	cmp    $0x1,%edx
f01011a3:	7e 16                	jle    f01011bb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01011a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a8:	8d 50 08             	lea    0x8(%eax),%edx
f01011ab:	89 55 14             	mov    %edx,0x14(%ebp)
f01011ae:	8b 50 04             	mov    0x4(%eax),%edx
f01011b1:	8b 00                	mov    (%eax),%eax
f01011b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01011b6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01011b9:	eb 32                	jmp    f01011ed <vprintfmt+0x2df>
	else if (lflag)
f01011bb:	85 d2                	test   %edx,%edx
f01011bd:	74 18                	je     f01011d7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f01011bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c2:	8d 50 04             	lea    0x4(%eax),%edx
f01011c5:	89 55 14             	mov    %edx,0x14(%ebp)
f01011c8:	8b 30                	mov    (%eax),%esi
f01011ca:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01011cd:	89 f0                	mov    %esi,%eax
f01011cf:	c1 f8 1f             	sar    $0x1f,%eax
f01011d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011d5:	eb 16                	jmp    f01011ed <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01011d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01011da:	8d 50 04             	lea    0x4(%eax),%edx
f01011dd:	89 55 14             	mov    %edx,0x14(%ebp)
f01011e0:	8b 30                	mov    (%eax),%esi
f01011e2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01011e5:	89 f0                	mov    %esi,%eax
f01011e7:	c1 f8 1f             	sar    $0x1f,%eax
f01011ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011ed:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011f0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011f3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011f8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01011fc:	0f 89 80 00 00 00    	jns    f0101282 <vprintfmt+0x374>
				putch('-', putdat);
f0101202:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101206:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010120d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101210:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101213:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101216:	f7 d8                	neg    %eax
f0101218:	83 d2 00             	adc    $0x0,%edx
f010121b:	f7 da                	neg    %edx
			}
			base = 10;
f010121d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101222:	eb 5e                	jmp    f0101282 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101224:	8d 45 14             	lea    0x14(%ebp),%eax
f0101227:	e8 63 fc ff ff       	call   f0100e8f <getuint>
			base = 10;
f010122c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101231:	eb 4f                	jmp    f0101282 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101233:	8d 45 14             	lea    0x14(%ebp),%eax
f0101236:	e8 54 fc ff ff       	call   f0100e8f <getuint>
			base = 8;
f010123b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101240:	eb 40                	jmp    f0101282 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0101242:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101246:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010124d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101250:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101254:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010125b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010125e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101261:	8d 50 04             	lea    0x4(%eax),%edx
f0101264:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101267:	8b 00                	mov    (%eax),%eax
f0101269:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010126e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101273:	eb 0d                	jmp    f0101282 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101275:	8d 45 14             	lea    0x14(%ebp),%eax
f0101278:	e8 12 fc ff ff       	call   f0100e8f <getuint>
			base = 16;
f010127d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101282:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0101286:	89 74 24 10          	mov    %esi,0x10(%esp)
f010128a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010128d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101291:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101295:	89 04 24             	mov    %eax,(%esp)
f0101298:	89 54 24 04          	mov    %edx,0x4(%esp)
f010129c:	89 fa                	mov    %edi,%edx
f010129e:	8b 45 08             	mov    0x8(%ebp),%eax
f01012a1:	e8 fa fa ff ff       	call   f0100da0 <printnum>
			break;
f01012a6:	e9 88 fc ff ff       	jmp    f0100f33 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012ab:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012af:	89 04 24             	mov    %eax,(%esp)
f01012b2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01012b5:	e9 79 fc ff ff       	jmp    f0100f33 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012ba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012be:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01012c5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012c8:	89 f3                	mov    %esi,%ebx
f01012ca:	eb 03                	jmp    f01012cf <vprintfmt+0x3c1>
f01012cc:	83 eb 01             	sub    $0x1,%ebx
f01012cf:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01012d3:	75 f7                	jne    f01012cc <vprintfmt+0x3be>
f01012d5:	e9 59 fc ff ff       	jmp    f0100f33 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01012da:	83 c4 3c             	add    $0x3c,%esp
f01012dd:	5b                   	pop    %ebx
f01012de:	5e                   	pop    %esi
f01012df:	5f                   	pop    %edi
f01012e0:	5d                   	pop    %ebp
f01012e1:	c3                   	ret    

f01012e2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012e2:	55                   	push   %ebp
f01012e3:	89 e5                	mov    %esp,%ebp
f01012e5:	83 ec 28             	sub    $0x28,%esp
f01012e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01012eb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012f1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012f5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012f8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012ff:	85 c0                	test   %eax,%eax
f0101301:	74 30                	je     f0101333 <vsnprintf+0x51>
f0101303:	85 d2                	test   %edx,%edx
f0101305:	7e 2c                	jle    f0101333 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101307:	8b 45 14             	mov    0x14(%ebp),%eax
f010130a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010130e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101311:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101315:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101318:	89 44 24 04          	mov    %eax,0x4(%esp)
f010131c:	c7 04 24 c9 0e 10 f0 	movl   $0xf0100ec9,(%esp)
f0101323:	e8 e6 fb ff ff       	call   f0100f0e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101328:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010132b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010132e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101331:	eb 05                	jmp    f0101338 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101333:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101338:	c9                   	leave  
f0101339:	c3                   	ret    

f010133a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010133a:	55                   	push   %ebp
f010133b:	89 e5                	mov    %esp,%ebp
f010133d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101340:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101343:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101347:	8b 45 10             	mov    0x10(%ebp),%eax
f010134a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010134e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101351:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101355:	8b 45 08             	mov    0x8(%ebp),%eax
f0101358:	89 04 24             	mov    %eax,(%esp)
f010135b:	e8 82 ff ff ff       	call   f01012e2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101360:	c9                   	leave  
f0101361:	c3                   	ret    
f0101362:	66 90                	xchg   %ax,%ax
f0101364:	66 90                	xchg   %ax,%ax
f0101366:	66 90                	xchg   %ax,%ax
f0101368:	66 90                	xchg   %ax,%ax
f010136a:	66 90                	xchg   %ax,%ax
f010136c:	66 90                	xchg   %ax,%ax
f010136e:	66 90                	xchg   %ax,%ax

f0101370 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101370:	55                   	push   %ebp
f0101371:	89 e5                	mov    %esp,%ebp
f0101373:	57                   	push   %edi
f0101374:	56                   	push   %esi
f0101375:	53                   	push   %ebx
f0101376:	83 ec 1c             	sub    $0x1c,%esp
f0101379:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010137c:	85 c0                	test   %eax,%eax
f010137e:	74 10                	je     f0101390 <readline+0x20>
		cprintf("%s", prompt);
f0101380:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101384:	c7 04 24 2a 20 10 f0 	movl   $0xf010202a,(%esp)
f010138b:	e8 cf f6 ff ff       	call   f0100a5f <cprintf>

	i = 0;
	echoing = iscons(0);
f0101390:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101397:	e8 e6 f2 ff ff       	call   f0100682 <iscons>
f010139c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010139e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013a3:	e8 c9 f2 ff ff       	call   f0100671 <getchar>
f01013a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013aa:	85 c0                	test   %eax,%eax
f01013ac:	79 17                	jns    f01013c5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01013ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013b2:	c7 04 24 0c 22 10 f0 	movl   $0xf010220c,(%esp)
f01013b9:	e8 a1 f6 ff ff       	call   f0100a5f <cprintf>
			return NULL;
f01013be:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c3:	eb 6d                	jmp    f0101432 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013c5:	83 f8 7f             	cmp    $0x7f,%eax
f01013c8:	74 05                	je     f01013cf <readline+0x5f>
f01013ca:	83 f8 08             	cmp    $0x8,%eax
f01013cd:	75 19                	jne    f01013e8 <readline+0x78>
f01013cf:	85 f6                	test   %esi,%esi
f01013d1:	7e 15                	jle    f01013e8 <readline+0x78>
			if (echoing)
f01013d3:	85 ff                	test   %edi,%edi
f01013d5:	74 0c                	je     f01013e3 <readline+0x73>
				cputchar('\b');
f01013d7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01013de:	e8 7e f2 ff ff       	call   f0100661 <cputchar>
			i--;
f01013e3:	83 ee 01             	sub    $0x1,%esi
f01013e6:	eb bb                	jmp    f01013a3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013e8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013ee:	7f 1c                	jg     f010140c <readline+0x9c>
f01013f0:	83 fb 1f             	cmp    $0x1f,%ebx
f01013f3:	7e 17                	jle    f010140c <readline+0x9c>
			if (echoing)
f01013f5:	85 ff                	test   %edi,%edi
f01013f7:	74 08                	je     f0101401 <readline+0x91>
				cputchar(c);
f01013f9:	89 1c 24             	mov    %ebx,(%esp)
f01013fc:	e8 60 f2 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101401:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101407:	8d 76 01             	lea    0x1(%esi),%esi
f010140a:	eb 97                	jmp    f01013a3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010140c:	83 fb 0d             	cmp    $0xd,%ebx
f010140f:	74 05                	je     f0101416 <readline+0xa6>
f0101411:	83 fb 0a             	cmp    $0xa,%ebx
f0101414:	75 8d                	jne    f01013a3 <readline+0x33>
			if (echoing)
f0101416:	85 ff                	test   %edi,%edi
f0101418:	74 0c                	je     f0101426 <readline+0xb6>
				cputchar('\n');
f010141a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101421:	e8 3b f2 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f0101426:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010142d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101432:	83 c4 1c             	add    $0x1c,%esp
f0101435:	5b                   	pop    %ebx
f0101436:	5e                   	pop    %esi
f0101437:	5f                   	pop    %edi
f0101438:	5d                   	pop    %ebp
f0101439:	c3                   	ret    
f010143a:	66 90                	xchg   %ax,%ax
f010143c:	66 90                	xchg   %ax,%ax
f010143e:	66 90                	xchg   %ax,%ax

f0101440 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101440:	55                   	push   %ebp
f0101441:	89 e5                	mov    %esp,%ebp
f0101443:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101446:	b8 00 00 00 00       	mov    $0x0,%eax
f010144b:	eb 03                	jmp    f0101450 <strlen+0x10>
		n++;
f010144d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101450:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101454:	75 f7                	jne    f010144d <strlen+0xd>
		n++;
	return n;
}
f0101456:	5d                   	pop    %ebp
f0101457:	c3                   	ret    

f0101458 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101458:	55                   	push   %ebp
f0101459:	89 e5                	mov    %esp,%ebp
f010145b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010145e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101461:	b8 00 00 00 00       	mov    $0x0,%eax
f0101466:	eb 03                	jmp    f010146b <strnlen+0x13>
		n++;
f0101468:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010146b:	39 d0                	cmp    %edx,%eax
f010146d:	74 06                	je     f0101475 <strnlen+0x1d>
f010146f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101473:	75 f3                	jne    f0101468 <strnlen+0x10>
		n++;
	return n;
}
f0101475:	5d                   	pop    %ebp
f0101476:	c3                   	ret    

f0101477 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101477:	55                   	push   %ebp
f0101478:	89 e5                	mov    %esp,%ebp
f010147a:	53                   	push   %ebx
f010147b:	8b 45 08             	mov    0x8(%ebp),%eax
f010147e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101481:	89 c2                	mov    %eax,%edx
f0101483:	83 c2 01             	add    $0x1,%edx
f0101486:	83 c1 01             	add    $0x1,%ecx
f0101489:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010148d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101490:	84 db                	test   %bl,%bl
f0101492:	75 ef                	jne    f0101483 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101494:	5b                   	pop    %ebx
f0101495:	5d                   	pop    %ebp
f0101496:	c3                   	ret    

f0101497 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101497:	55                   	push   %ebp
f0101498:	89 e5                	mov    %esp,%ebp
f010149a:	53                   	push   %ebx
f010149b:	83 ec 08             	sub    $0x8,%esp
f010149e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014a1:	89 1c 24             	mov    %ebx,(%esp)
f01014a4:	e8 97 ff ff ff       	call   f0101440 <strlen>
	strcpy(dst + len, src);
f01014a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014ac:	89 54 24 04          	mov    %edx,0x4(%esp)
f01014b0:	01 d8                	add    %ebx,%eax
f01014b2:	89 04 24             	mov    %eax,(%esp)
f01014b5:	e8 bd ff ff ff       	call   f0101477 <strcpy>
	return dst;
}
f01014ba:	89 d8                	mov    %ebx,%eax
f01014bc:	83 c4 08             	add    $0x8,%esp
f01014bf:	5b                   	pop    %ebx
f01014c0:	5d                   	pop    %ebp
f01014c1:	c3                   	ret    

f01014c2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014c2:	55                   	push   %ebp
f01014c3:	89 e5                	mov    %esp,%ebp
f01014c5:	56                   	push   %esi
f01014c6:	53                   	push   %ebx
f01014c7:	8b 75 08             	mov    0x8(%ebp),%esi
f01014ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014cd:	89 f3                	mov    %esi,%ebx
f01014cf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014d2:	89 f2                	mov    %esi,%edx
f01014d4:	eb 0f                	jmp    f01014e5 <strncpy+0x23>
		*dst++ = *src;
f01014d6:	83 c2 01             	add    $0x1,%edx
f01014d9:	0f b6 01             	movzbl (%ecx),%eax
f01014dc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014df:	80 39 01             	cmpb   $0x1,(%ecx)
f01014e2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014e5:	39 da                	cmp    %ebx,%edx
f01014e7:	75 ed                	jne    f01014d6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01014e9:	89 f0                	mov    %esi,%eax
f01014eb:	5b                   	pop    %ebx
f01014ec:	5e                   	pop    %esi
f01014ed:	5d                   	pop    %ebp
f01014ee:	c3                   	ret    

f01014ef <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01014ef:	55                   	push   %ebp
f01014f0:	89 e5                	mov    %esp,%ebp
f01014f2:	56                   	push   %esi
f01014f3:	53                   	push   %ebx
f01014f4:	8b 75 08             	mov    0x8(%ebp),%esi
f01014f7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014fa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01014fd:	89 f0                	mov    %esi,%eax
f01014ff:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101503:	85 c9                	test   %ecx,%ecx
f0101505:	75 0b                	jne    f0101512 <strlcpy+0x23>
f0101507:	eb 1d                	jmp    f0101526 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101509:	83 c0 01             	add    $0x1,%eax
f010150c:	83 c2 01             	add    $0x1,%edx
f010150f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101512:	39 d8                	cmp    %ebx,%eax
f0101514:	74 0b                	je     f0101521 <strlcpy+0x32>
f0101516:	0f b6 0a             	movzbl (%edx),%ecx
f0101519:	84 c9                	test   %cl,%cl
f010151b:	75 ec                	jne    f0101509 <strlcpy+0x1a>
f010151d:	89 c2                	mov    %eax,%edx
f010151f:	eb 02                	jmp    f0101523 <strlcpy+0x34>
f0101521:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101523:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101526:	29 f0                	sub    %esi,%eax
}
f0101528:	5b                   	pop    %ebx
f0101529:	5e                   	pop    %esi
f010152a:	5d                   	pop    %ebp
f010152b:	c3                   	ret    

f010152c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010152c:	55                   	push   %ebp
f010152d:	89 e5                	mov    %esp,%ebp
f010152f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101532:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101535:	eb 06                	jmp    f010153d <strcmp+0x11>
		p++, q++;
f0101537:	83 c1 01             	add    $0x1,%ecx
f010153a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010153d:	0f b6 01             	movzbl (%ecx),%eax
f0101540:	84 c0                	test   %al,%al
f0101542:	74 04                	je     f0101548 <strcmp+0x1c>
f0101544:	3a 02                	cmp    (%edx),%al
f0101546:	74 ef                	je     f0101537 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101548:	0f b6 c0             	movzbl %al,%eax
f010154b:	0f b6 12             	movzbl (%edx),%edx
f010154e:	29 d0                	sub    %edx,%eax
}
f0101550:	5d                   	pop    %ebp
f0101551:	c3                   	ret    

f0101552 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101552:	55                   	push   %ebp
f0101553:	89 e5                	mov    %esp,%ebp
f0101555:	53                   	push   %ebx
f0101556:	8b 45 08             	mov    0x8(%ebp),%eax
f0101559:	8b 55 0c             	mov    0xc(%ebp),%edx
f010155c:	89 c3                	mov    %eax,%ebx
f010155e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101561:	eb 06                	jmp    f0101569 <strncmp+0x17>
		n--, p++, q++;
f0101563:	83 c0 01             	add    $0x1,%eax
f0101566:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101569:	39 d8                	cmp    %ebx,%eax
f010156b:	74 15                	je     f0101582 <strncmp+0x30>
f010156d:	0f b6 08             	movzbl (%eax),%ecx
f0101570:	84 c9                	test   %cl,%cl
f0101572:	74 04                	je     f0101578 <strncmp+0x26>
f0101574:	3a 0a                	cmp    (%edx),%cl
f0101576:	74 eb                	je     f0101563 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101578:	0f b6 00             	movzbl (%eax),%eax
f010157b:	0f b6 12             	movzbl (%edx),%edx
f010157e:	29 d0                	sub    %edx,%eax
f0101580:	eb 05                	jmp    f0101587 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101582:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101587:	5b                   	pop    %ebx
f0101588:	5d                   	pop    %ebp
f0101589:	c3                   	ret    

f010158a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010158a:	55                   	push   %ebp
f010158b:	89 e5                	mov    %esp,%ebp
f010158d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101590:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101594:	eb 07                	jmp    f010159d <strchr+0x13>
		if (*s == c)
f0101596:	38 ca                	cmp    %cl,%dl
f0101598:	74 0f                	je     f01015a9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010159a:	83 c0 01             	add    $0x1,%eax
f010159d:	0f b6 10             	movzbl (%eax),%edx
f01015a0:	84 d2                	test   %dl,%dl
f01015a2:	75 f2                	jne    f0101596 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01015a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015a9:	5d                   	pop    %ebp
f01015aa:	c3                   	ret    

f01015ab <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015ab:	55                   	push   %ebp
f01015ac:	89 e5                	mov    %esp,%ebp
f01015ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01015b1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015b5:	eb 07                	jmp    f01015be <strfind+0x13>
		if (*s == c)
f01015b7:	38 ca                	cmp    %cl,%dl
f01015b9:	74 0a                	je     f01015c5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01015bb:	83 c0 01             	add    $0x1,%eax
f01015be:	0f b6 10             	movzbl (%eax),%edx
f01015c1:	84 d2                	test   %dl,%dl
f01015c3:	75 f2                	jne    f01015b7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01015c5:	5d                   	pop    %ebp
f01015c6:	c3                   	ret    

f01015c7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015c7:	55                   	push   %ebp
f01015c8:	89 e5                	mov    %esp,%ebp
f01015ca:	57                   	push   %edi
f01015cb:	56                   	push   %esi
f01015cc:	53                   	push   %ebx
f01015cd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015d0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015d3:	85 c9                	test   %ecx,%ecx
f01015d5:	74 36                	je     f010160d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015d7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015dd:	75 28                	jne    f0101607 <memset+0x40>
f01015df:	f6 c1 03             	test   $0x3,%cl
f01015e2:	75 23                	jne    f0101607 <memset+0x40>
		c &= 0xFF;
f01015e4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015e8:	89 d3                	mov    %edx,%ebx
f01015ea:	c1 e3 08             	shl    $0x8,%ebx
f01015ed:	89 d6                	mov    %edx,%esi
f01015ef:	c1 e6 18             	shl    $0x18,%esi
f01015f2:	89 d0                	mov    %edx,%eax
f01015f4:	c1 e0 10             	shl    $0x10,%eax
f01015f7:	09 f0                	or     %esi,%eax
f01015f9:	09 c2                	or     %eax,%edx
f01015fb:	89 d0                	mov    %edx,%eax
f01015fd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01015ff:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101602:	fc                   	cld    
f0101603:	f3 ab                	rep stos %eax,%es:(%edi)
f0101605:	eb 06                	jmp    f010160d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101607:	8b 45 0c             	mov    0xc(%ebp),%eax
f010160a:	fc                   	cld    
f010160b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010160d:	89 f8                	mov    %edi,%eax
f010160f:	5b                   	pop    %ebx
f0101610:	5e                   	pop    %esi
f0101611:	5f                   	pop    %edi
f0101612:	5d                   	pop    %ebp
f0101613:	c3                   	ret    

f0101614 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101614:	55                   	push   %ebp
f0101615:	89 e5                	mov    %esp,%ebp
f0101617:	57                   	push   %edi
f0101618:	56                   	push   %esi
f0101619:	8b 45 08             	mov    0x8(%ebp),%eax
f010161c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010161f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101622:	39 c6                	cmp    %eax,%esi
f0101624:	73 35                	jae    f010165b <memmove+0x47>
f0101626:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101629:	39 d0                	cmp    %edx,%eax
f010162b:	73 2e                	jae    f010165b <memmove+0x47>
		s += n;
		d += n;
f010162d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101630:	89 d6                	mov    %edx,%esi
f0101632:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101634:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010163a:	75 13                	jne    f010164f <memmove+0x3b>
f010163c:	f6 c1 03             	test   $0x3,%cl
f010163f:	75 0e                	jne    f010164f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101641:	83 ef 04             	sub    $0x4,%edi
f0101644:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101647:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010164a:	fd                   	std    
f010164b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010164d:	eb 09                	jmp    f0101658 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010164f:	83 ef 01             	sub    $0x1,%edi
f0101652:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101655:	fd                   	std    
f0101656:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101658:	fc                   	cld    
f0101659:	eb 1d                	jmp    f0101678 <memmove+0x64>
f010165b:	89 f2                	mov    %esi,%edx
f010165d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010165f:	f6 c2 03             	test   $0x3,%dl
f0101662:	75 0f                	jne    f0101673 <memmove+0x5f>
f0101664:	f6 c1 03             	test   $0x3,%cl
f0101667:	75 0a                	jne    f0101673 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101669:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010166c:	89 c7                	mov    %eax,%edi
f010166e:	fc                   	cld    
f010166f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101671:	eb 05                	jmp    f0101678 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101673:	89 c7                	mov    %eax,%edi
f0101675:	fc                   	cld    
f0101676:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101678:	5e                   	pop    %esi
f0101679:	5f                   	pop    %edi
f010167a:	5d                   	pop    %ebp
f010167b:	c3                   	ret    

f010167c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010167c:	55                   	push   %ebp
f010167d:	89 e5                	mov    %esp,%ebp
f010167f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101682:	8b 45 10             	mov    0x10(%ebp),%eax
f0101685:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101689:	8b 45 0c             	mov    0xc(%ebp),%eax
f010168c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101690:	8b 45 08             	mov    0x8(%ebp),%eax
f0101693:	89 04 24             	mov    %eax,(%esp)
f0101696:	e8 79 ff ff ff       	call   f0101614 <memmove>
}
f010169b:	c9                   	leave  
f010169c:	c3                   	ret    

f010169d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010169d:	55                   	push   %ebp
f010169e:	89 e5                	mov    %esp,%ebp
f01016a0:	56                   	push   %esi
f01016a1:	53                   	push   %ebx
f01016a2:	8b 55 08             	mov    0x8(%ebp),%edx
f01016a5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01016a8:	89 d6                	mov    %edx,%esi
f01016aa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016ad:	eb 1a                	jmp    f01016c9 <memcmp+0x2c>
		if (*s1 != *s2)
f01016af:	0f b6 02             	movzbl (%edx),%eax
f01016b2:	0f b6 19             	movzbl (%ecx),%ebx
f01016b5:	38 d8                	cmp    %bl,%al
f01016b7:	74 0a                	je     f01016c3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01016b9:	0f b6 c0             	movzbl %al,%eax
f01016bc:	0f b6 db             	movzbl %bl,%ebx
f01016bf:	29 d8                	sub    %ebx,%eax
f01016c1:	eb 0f                	jmp    f01016d2 <memcmp+0x35>
		s1++, s2++;
f01016c3:	83 c2 01             	add    $0x1,%edx
f01016c6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016c9:	39 f2                	cmp    %esi,%edx
f01016cb:	75 e2                	jne    f01016af <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016d2:	5b                   	pop    %ebx
f01016d3:	5e                   	pop    %esi
f01016d4:	5d                   	pop    %ebp
f01016d5:	c3                   	ret    

f01016d6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016d6:	55                   	push   %ebp
f01016d7:	89 e5                	mov    %esp,%ebp
f01016d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01016dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01016df:	89 c2                	mov    %eax,%edx
f01016e1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016e4:	eb 07                	jmp    f01016ed <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016e6:	38 08                	cmp    %cl,(%eax)
f01016e8:	74 07                	je     f01016f1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016ea:	83 c0 01             	add    $0x1,%eax
f01016ed:	39 d0                	cmp    %edx,%eax
f01016ef:	72 f5                	jb     f01016e6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01016f1:	5d                   	pop    %ebp
f01016f2:	c3                   	ret    

f01016f3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01016f3:	55                   	push   %ebp
f01016f4:	89 e5                	mov    %esp,%ebp
f01016f6:	57                   	push   %edi
f01016f7:	56                   	push   %esi
f01016f8:	53                   	push   %ebx
f01016f9:	8b 55 08             	mov    0x8(%ebp),%edx
f01016fc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016ff:	eb 03                	jmp    f0101704 <strtol+0x11>
		s++;
f0101701:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101704:	0f b6 0a             	movzbl (%edx),%ecx
f0101707:	80 f9 09             	cmp    $0x9,%cl
f010170a:	74 f5                	je     f0101701 <strtol+0xe>
f010170c:	80 f9 20             	cmp    $0x20,%cl
f010170f:	74 f0                	je     f0101701 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101711:	80 f9 2b             	cmp    $0x2b,%cl
f0101714:	75 0a                	jne    f0101720 <strtol+0x2d>
		s++;
f0101716:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101719:	bf 00 00 00 00       	mov    $0x0,%edi
f010171e:	eb 11                	jmp    f0101731 <strtol+0x3e>
f0101720:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101725:	80 f9 2d             	cmp    $0x2d,%cl
f0101728:	75 07                	jne    f0101731 <strtol+0x3e>
		s++, neg = 1;
f010172a:	8d 52 01             	lea    0x1(%edx),%edx
f010172d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101731:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101736:	75 15                	jne    f010174d <strtol+0x5a>
f0101738:	80 3a 30             	cmpb   $0x30,(%edx)
f010173b:	75 10                	jne    f010174d <strtol+0x5a>
f010173d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101741:	75 0a                	jne    f010174d <strtol+0x5a>
		s += 2, base = 16;
f0101743:	83 c2 02             	add    $0x2,%edx
f0101746:	b8 10 00 00 00       	mov    $0x10,%eax
f010174b:	eb 10                	jmp    f010175d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010174d:	85 c0                	test   %eax,%eax
f010174f:	75 0c                	jne    f010175d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101751:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101753:	80 3a 30             	cmpb   $0x30,(%edx)
f0101756:	75 05                	jne    f010175d <strtol+0x6a>
		s++, base = 8;
f0101758:	83 c2 01             	add    $0x1,%edx
f010175b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010175d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101762:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101765:	0f b6 0a             	movzbl (%edx),%ecx
f0101768:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010176b:	89 f0                	mov    %esi,%eax
f010176d:	3c 09                	cmp    $0x9,%al
f010176f:	77 08                	ja     f0101779 <strtol+0x86>
			dig = *s - '0';
f0101771:	0f be c9             	movsbl %cl,%ecx
f0101774:	83 e9 30             	sub    $0x30,%ecx
f0101777:	eb 20                	jmp    f0101799 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101779:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010177c:	89 f0                	mov    %esi,%eax
f010177e:	3c 19                	cmp    $0x19,%al
f0101780:	77 08                	ja     f010178a <strtol+0x97>
			dig = *s - 'a' + 10;
f0101782:	0f be c9             	movsbl %cl,%ecx
f0101785:	83 e9 57             	sub    $0x57,%ecx
f0101788:	eb 0f                	jmp    f0101799 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010178a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010178d:	89 f0                	mov    %esi,%eax
f010178f:	3c 19                	cmp    $0x19,%al
f0101791:	77 16                	ja     f01017a9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0101793:	0f be c9             	movsbl %cl,%ecx
f0101796:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101799:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010179c:	7d 0f                	jge    f01017ad <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010179e:	83 c2 01             	add    $0x1,%edx
f01017a1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01017a5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01017a7:	eb bc                	jmp    f0101765 <strtol+0x72>
f01017a9:	89 d8                	mov    %ebx,%eax
f01017ab:	eb 02                	jmp    f01017af <strtol+0xbc>
f01017ad:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01017af:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017b3:	74 05                	je     f01017ba <strtol+0xc7>
		*endptr = (char *) s;
f01017b5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017b8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01017ba:	f7 d8                	neg    %eax
f01017bc:	85 ff                	test   %edi,%edi
f01017be:	0f 44 c3             	cmove  %ebx,%eax
}
f01017c1:	5b                   	pop    %ebx
f01017c2:	5e                   	pop    %esi
f01017c3:	5f                   	pop    %edi
f01017c4:	5d                   	pop    %ebp
f01017c5:	c3                   	ret    
f01017c6:	66 90                	xchg   %ax,%ax
f01017c8:	66 90                	xchg   %ax,%ax
f01017ca:	66 90                	xchg   %ax,%ax
f01017cc:	66 90                	xchg   %ax,%ax
f01017ce:	66 90                	xchg   %ax,%ax

f01017d0 <__udivdi3>:
f01017d0:	55                   	push   %ebp
f01017d1:	57                   	push   %edi
f01017d2:	56                   	push   %esi
f01017d3:	83 ec 0c             	sub    $0xc,%esp
f01017d6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017da:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01017de:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01017e2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017e6:	85 c0                	test   %eax,%eax
f01017e8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017ec:	89 ea                	mov    %ebp,%edx
f01017ee:	89 0c 24             	mov    %ecx,(%esp)
f01017f1:	75 2d                	jne    f0101820 <__udivdi3+0x50>
f01017f3:	39 e9                	cmp    %ebp,%ecx
f01017f5:	77 61                	ja     f0101858 <__udivdi3+0x88>
f01017f7:	85 c9                	test   %ecx,%ecx
f01017f9:	89 ce                	mov    %ecx,%esi
f01017fb:	75 0b                	jne    f0101808 <__udivdi3+0x38>
f01017fd:	b8 01 00 00 00       	mov    $0x1,%eax
f0101802:	31 d2                	xor    %edx,%edx
f0101804:	f7 f1                	div    %ecx
f0101806:	89 c6                	mov    %eax,%esi
f0101808:	31 d2                	xor    %edx,%edx
f010180a:	89 e8                	mov    %ebp,%eax
f010180c:	f7 f6                	div    %esi
f010180e:	89 c5                	mov    %eax,%ebp
f0101810:	89 f8                	mov    %edi,%eax
f0101812:	f7 f6                	div    %esi
f0101814:	89 ea                	mov    %ebp,%edx
f0101816:	83 c4 0c             	add    $0xc,%esp
f0101819:	5e                   	pop    %esi
f010181a:	5f                   	pop    %edi
f010181b:	5d                   	pop    %ebp
f010181c:	c3                   	ret    
f010181d:	8d 76 00             	lea    0x0(%esi),%esi
f0101820:	39 e8                	cmp    %ebp,%eax
f0101822:	77 24                	ja     f0101848 <__udivdi3+0x78>
f0101824:	0f bd e8             	bsr    %eax,%ebp
f0101827:	83 f5 1f             	xor    $0x1f,%ebp
f010182a:	75 3c                	jne    f0101868 <__udivdi3+0x98>
f010182c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101830:	39 34 24             	cmp    %esi,(%esp)
f0101833:	0f 86 9f 00 00 00    	jbe    f01018d8 <__udivdi3+0x108>
f0101839:	39 d0                	cmp    %edx,%eax
f010183b:	0f 82 97 00 00 00    	jb     f01018d8 <__udivdi3+0x108>
f0101841:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101848:	31 d2                	xor    %edx,%edx
f010184a:	31 c0                	xor    %eax,%eax
f010184c:	83 c4 0c             	add    $0xc,%esp
f010184f:	5e                   	pop    %esi
f0101850:	5f                   	pop    %edi
f0101851:	5d                   	pop    %ebp
f0101852:	c3                   	ret    
f0101853:	90                   	nop
f0101854:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101858:	89 f8                	mov    %edi,%eax
f010185a:	f7 f1                	div    %ecx
f010185c:	31 d2                	xor    %edx,%edx
f010185e:	83 c4 0c             	add    $0xc,%esp
f0101861:	5e                   	pop    %esi
f0101862:	5f                   	pop    %edi
f0101863:	5d                   	pop    %ebp
f0101864:	c3                   	ret    
f0101865:	8d 76 00             	lea    0x0(%esi),%esi
f0101868:	89 e9                	mov    %ebp,%ecx
f010186a:	8b 3c 24             	mov    (%esp),%edi
f010186d:	d3 e0                	shl    %cl,%eax
f010186f:	89 c6                	mov    %eax,%esi
f0101871:	b8 20 00 00 00       	mov    $0x20,%eax
f0101876:	29 e8                	sub    %ebp,%eax
f0101878:	89 c1                	mov    %eax,%ecx
f010187a:	d3 ef                	shr    %cl,%edi
f010187c:	89 e9                	mov    %ebp,%ecx
f010187e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101882:	8b 3c 24             	mov    (%esp),%edi
f0101885:	09 74 24 08          	or     %esi,0x8(%esp)
f0101889:	89 d6                	mov    %edx,%esi
f010188b:	d3 e7                	shl    %cl,%edi
f010188d:	89 c1                	mov    %eax,%ecx
f010188f:	89 3c 24             	mov    %edi,(%esp)
f0101892:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101896:	d3 ee                	shr    %cl,%esi
f0101898:	89 e9                	mov    %ebp,%ecx
f010189a:	d3 e2                	shl    %cl,%edx
f010189c:	89 c1                	mov    %eax,%ecx
f010189e:	d3 ef                	shr    %cl,%edi
f01018a0:	09 d7                	or     %edx,%edi
f01018a2:	89 f2                	mov    %esi,%edx
f01018a4:	89 f8                	mov    %edi,%eax
f01018a6:	f7 74 24 08          	divl   0x8(%esp)
f01018aa:	89 d6                	mov    %edx,%esi
f01018ac:	89 c7                	mov    %eax,%edi
f01018ae:	f7 24 24             	mull   (%esp)
f01018b1:	39 d6                	cmp    %edx,%esi
f01018b3:	89 14 24             	mov    %edx,(%esp)
f01018b6:	72 30                	jb     f01018e8 <__udivdi3+0x118>
f01018b8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01018bc:	89 e9                	mov    %ebp,%ecx
f01018be:	d3 e2                	shl    %cl,%edx
f01018c0:	39 c2                	cmp    %eax,%edx
f01018c2:	73 05                	jae    f01018c9 <__udivdi3+0xf9>
f01018c4:	3b 34 24             	cmp    (%esp),%esi
f01018c7:	74 1f                	je     f01018e8 <__udivdi3+0x118>
f01018c9:	89 f8                	mov    %edi,%eax
f01018cb:	31 d2                	xor    %edx,%edx
f01018cd:	e9 7a ff ff ff       	jmp    f010184c <__udivdi3+0x7c>
f01018d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018d8:	31 d2                	xor    %edx,%edx
f01018da:	b8 01 00 00 00       	mov    $0x1,%eax
f01018df:	e9 68 ff ff ff       	jmp    f010184c <__udivdi3+0x7c>
f01018e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018e8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01018eb:	31 d2                	xor    %edx,%edx
f01018ed:	83 c4 0c             	add    $0xc,%esp
f01018f0:	5e                   	pop    %esi
f01018f1:	5f                   	pop    %edi
f01018f2:	5d                   	pop    %ebp
f01018f3:	c3                   	ret    
f01018f4:	66 90                	xchg   %ax,%ax
f01018f6:	66 90                	xchg   %ax,%ax
f01018f8:	66 90                	xchg   %ax,%ax
f01018fa:	66 90                	xchg   %ax,%ax
f01018fc:	66 90                	xchg   %ax,%ax
f01018fe:	66 90                	xchg   %ax,%ax

f0101900 <__umoddi3>:
f0101900:	55                   	push   %ebp
f0101901:	57                   	push   %edi
f0101902:	56                   	push   %esi
f0101903:	83 ec 14             	sub    $0x14,%esp
f0101906:	8b 44 24 28          	mov    0x28(%esp),%eax
f010190a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010190e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101912:	89 c7                	mov    %eax,%edi
f0101914:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101918:	8b 44 24 30          	mov    0x30(%esp),%eax
f010191c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101920:	89 34 24             	mov    %esi,(%esp)
f0101923:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101927:	85 c0                	test   %eax,%eax
f0101929:	89 c2                	mov    %eax,%edx
f010192b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010192f:	75 17                	jne    f0101948 <__umoddi3+0x48>
f0101931:	39 fe                	cmp    %edi,%esi
f0101933:	76 4b                	jbe    f0101980 <__umoddi3+0x80>
f0101935:	89 c8                	mov    %ecx,%eax
f0101937:	89 fa                	mov    %edi,%edx
f0101939:	f7 f6                	div    %esi
f010193b:	89 d0                	mov    %edx,%eax
f010193d:	31 d2                	xor    %edx,%edx
f010193f:	83 c4 14             	add    $0x14,%esp
f0101942:	5e                   	pop    %esi
f0101943:	5f                   	pop    %edi
f0101944:	5d                   	pop    %ebp
f0101945:	c3                   	ret    
f0101946:	66 90                	xchg   %ax,%ax
f0101948:	39 f8                	cmp    %edi,%eax
f010194a:	77 54                	ja     f01019a0 <__umoddi3+0xa0>
f010194c:	0f bd e8             	bsr    %eax,%ebp
f010194f:	83 f5 1f             	xor    $0x1f,%ebp
f0101952:	75 5c                	jne    f01019b0 <__umoddi3+0xb0>
f0101954:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101958:	39 3c 24             	cmp    %edi,(%esp)
f010195b:	0f 87 e7 00 00 00    	ja     f0101a48 <__umoddi3+0x148>
f0101961:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101965:	29 f1                	sub    %esi,%ecx
f0101967:	19 c7                	sbb    %eax,%edi
f0101969:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010196d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101971:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101975:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101979:	83 c4 14             	add    $0x14,%esp
f010197c:	5e                   	pop    %esi
f010197d:	5f                   	pop    %edi
f010197e:	5d                   	pop    %ebp
f010197f:	c3                   	ret    
f0101980:	85 f6                	test   %esi,%esi
f0101982:	89 f5                	mov    %esi,%ebp
f0101984:	75 0b                	jne    f0101991 <__umoddi3+0x91>
f0101986:	b8 01 00 00 00       	mov    $0x1,%eax
f010198b:	31 d2                	xor    %edx,%edx
f010198d:	f7 f6                	div    %esi
f010198f:	89 c5                	mov    %eax,%ebp
f0101991:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101995:	31 d2                	xor    %edx,%edx
f0101997:	f7 f5                	div    %ebp
f0101999:	89 c8                	mov    %ecx,%eax
f010199b:	f7 f5                	div    %ebp
f010199d:	eb 9c                	jmp    f010193b <__umoddi3+0x3b>
f010199f:	90                   	nop
f01019a0:	89 c8                	mov    %ecx,%eax
f01019a2:	89 fa                	mov    %edi,%edx
f01019a4:	83 c4 14             	add    $0x14,%esp
f01019a7:	5e                   	pop    %esi
f01019a8:	5f                   	pop    %edi
f01019a9:	5d                   	pop    %ebp
f01019aa:	c3                   	ret    
f01019ab:	90                   	nop
f01019ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019b0:	8b 04 24             	mov    (%esp),%eax
f01019b3:	be 20 00 00 00       	mov    $0x20,%esi
f01019b8:	89 e9                	mov    %ebp,%ecx
f01019ba:	29 ee                	sub    %ebp,%esi
f01019bc:	d3 e2                	shl    %cl,%edx
f01019be:	89 f1                	mov    %esi,%ecx
f01019c0:	d3 e8                	shr    %cl,%eax
f01019c2:	89 e9                	mov    %ebp,%ecx
f01019c4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019c8:	8b 04 24             	mov    (%esp),%eax
f01019cb:	09 54 24 04          	or     %edx,0x4(%esp)
f01019cf:	89 fa                	mov    %edi,%edx
f01019d1:	d3 e0                	shl    %cl,%eax
f01019d3:	89 f1                	mov    %esi,%ecx
f01019d5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019d9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01019dd:	d3 ea                	shr    %cl,%edx
f01019df:	89 e9                	mov    %ebp,%ecx
f01019e1:	d3 e7                	shl    %cl,%edi
f01019e3:	89 f1                	mov    %esi,%ecx
f01019e5:	d3 e8                	shr    %cl,%eax
f01019e7:	89 e9                	mov    %ebp,%ecx
f01019e9:	09 f8                	or     %edi,%eax
f01019eb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01019ef:	f7 74 24 04          	divl   0x4(%esp)
f01019f3:	d3 e7                	shl    %cl,%edi
f01019f5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019f9:	89 d7                	mov    %edx,%edi
f01019fb:	f7 64 24 08          	mull   0x8(%esp)
f01019ff:	39 d7                	cmp    %edx,%edi
f0101a01:	89 c1                	mov    %eax,%ecx
f0101a03:	89 14 24             	mov    %edx,(%esp)
f0101a06:	72 2c                	jb     f0101a34 <__umoddi3+0x134>
f0101a08:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101a0c:	72 22                	jb     f0101a30 <__umoddi3+0x130>
f0101a0e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101a12:	29 c8                	sub    %ecx,%eax
f0101a14:	19 d7                	sbb    %edx,%edi
f0101a16:	89 e9                	mov    %ebp,%ecx
f0101a18:	89 fa                	mov    %edi,%edx
f0101a1a:	d3 e8                	shr    %cl,%eax
f0101a1c:	89 f1                	mov    %esi,%ecx
f0101a1e:	d3 e2                	shl    %cl,%edx
f0101a20:	89 e9                	mov    %ebp,%ecx
f0101a22:	d3 ef                	shr    %cl,%edi
f0101a24:	09 d0                	or     %edx,%eax
f0101a26:	89 fa                	mov    %edi,%edx
f0101a28:	83 c4 14             	add    $0x14,%esp
f0101a2b:	5e                   	pop    %esi
f0101a2c:	5f                   	pop    %edi
f0101a2d:	5d                   	pop    %ebp
f0101a2e:	c3                   	ret    
f0101a2f:	90                   	nop
f0101a30:	39 d7                	cmp    %edx,%edi
f0101a32:	75 da                	jne    f0101a0e <__umoddi3+0x10e>
f0101a34:	8b 14 24             	mov    (%esp),%edx
f0101a37:	89 c1                	mov    %eax,%ecx
f0101a39:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a3d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a41:	eb cb                	jmp    f0101a0e <__umoddi3+0x10e>
f0101a43:	90                   	nop
f0101a44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a48:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a4c:	0f 82 0f ff ff ff    	jb     f0101961 <__umoddi3+0x61>
f0101a52:	e9 1a ff ff ff       	jmp    f0101971 <__umoddi3+0x71>
