.intel_syntax

call_test:
	MOV	eax, 0x11
	CALL	subroutine
	MOV	byte ptr [0x10], al
	JMP	branch_test	

subroutine:
	ADD	eax, 0x22
	RET

branch_test:
	XOR	eax, eax
	JZ		alu_test
	MOV	byte ptr [0x11], 0xEE
	HLT

alu_test:
	MOV	ebx, 0x14
	MOV	ecx, 0x06
	LEA		eax, [ebx + ecx]
	SUB	eax, ecx
	ADD	eax, 0x05
	SUB	eax, 0x01
	MOV	byte ptr [0x12], al

logic_test:
	MOV	eax, 0x3C
	MOV	ebx, 0x0F
	MOV	eax, ebx
	AND	eax, ebx
	OR		eax, ebx
	XOR	eax, 0x3C
	NOT	eax
	MOV	byte ptr [0x13], al

shift_test:
	MOV	edx, 0x81
	MOV	ecx, 0x02
	MOV	eax, edx
	MOV	ebx, edx
	SHL		bl, cl
	SAR		al, cl
	SHR		bl, cl
	ROL		al, cl
	ROR	al, cl
	MOV	byte ptr [0x14], al

ind_addr_test:
	MOV	eax, 0x20
	MOV	ebx, 0x55
	ADD	eax, 0x03
	MOV	byte ptr [eax], bl
	MOV	ebx, [eax]
	MOV	byte ptr [0x15], bl

stack_test:
	MOV	eax, 0xAA
	PUSH	rax
	XOR	eax, eax
	POP	rax
	MOV	byte ptr [0x16], al

final_signature:
	MOV	byte ptr [0x11], 0x5A
	HLT