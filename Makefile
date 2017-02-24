AS := as
ASFLAGS := -g
LD := ld
LDFLAGS := 
NAME := wc

.PHONY = clean

all: $(NAME)

wc: wc.o
	$(LD) $(LDFLAGS) -o $@ $<

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

clean:
	rm -rf *.o rm -rf $(NAME)
