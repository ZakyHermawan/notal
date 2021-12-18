#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <system_error>

#include "ast.h"
#include "Codegen.h"
#include "parser.hpp"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Host.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"

llvm::Function* Codegen::printf;
std::vector<int> Codegen::labels;
llvm::Function* createPrintf(Codegen& context) {
	std::vector<llvm::Type *> printf_arg_types;
    printf_arg_types.push_back(llvm::Type::getInt8PtrTy(TheContext));
    auto printf_type = llvm::FunctionType::get(llvm::Type::getInt32Ty(TheContext), printf_arg_types, true);
    auto func = llvm::Function::Create(printf_type, llvm::Function::ExternalLinkage, llvm::Twine("printf"), context.module);
    func->setCallingConv(llvm::CallingConv::C);
    return func;
}

/* Compile the AST into a module */
void Codegen::generateCode(ast::Program& root)
{

	std::cout << "Generating code...\n";
	
	/* Create the top level interpreter function to call as entry */
	std::vector<Type*> argTypes;
	FunctionType *ftype = FunctionType::get(Type::getVoidTy(TheContext), makeArrayRef(argTypes), false);
	// change GlobalValue::InternalLinkage into ExternalLinkage
	mainFunction = Function::Create(ftype, GlobalValue::ExternalLinkage, "main", module);
	BasicBlock *bblock = BasicBlock::Create(TheContext, "entry", mainFunction, 0);
	
	Codegen::printf = createPrintf(*this);

	/* Push a new variable/block context */
	pushBlock(bblock);
	currentFunction = mainFunction;
	for (auto label:labels){
		labelBlock[label]=BasicBlock::Create(TheContext, "label", mainFunction, 0);
	}
	root.CodeGen(*this); /* emit bytecode for the toplevel block */
	ReturnInst::Create(TheContext, currentBlock());
	popBlock();
	// popBlock();
	
	/* Print the bytecode in a human-readable format 
	   to see if our program compiled properly
	 */
	std::cout << "Code is generated.\n";

        auto TargetTriple = sys::getDefaultTargetTriple();
        module->setTargetTriple(TargetTriple);
        std::string err;
        auto Target = TargetRegistry::lookupTarget(TargetTriple, err);
        if(!Target) {
          errs() << err;
        }
        auto CPU = "generic";
        auto Features = "";
        TargetOptions opt;
        auto RM = Optional<Reloc::Model>();
        auto TheTargetMachine = Target->createTargetMachine(TargetTriple, CPU, Features, opt, RM);
        module->setDataLayout(TheTargetMachine->createDataLayout());
        auto Filename = "output.o";
        std::error_code EC;
        raw_fd_ostream dest(Filename, EC, sys::fs::OF_None);
        if(EC) {
          errs() << "Could not open file: " << EC.message();
        }




        legacy::PassManager pm;
        auto FileType = CGFT_ObjectFile;
        if(TheTargetMachine->addPassesToEmitFile(pm, dest, nullptr, FileType)) {
          errs() << "Target Machine can't emit a file of this type\n";
        }
	pm.add(createPrintModulePass(outs()));
	pm.run(*module);
        dest.flush();

    // write IR to stderr
    /*
    std::cout<<"code is gen~~~\n";
    std::cout << "Generated code:\n";
    module->print(llvm::errs(), nullptr);
    std::cout<<"code is gen~!~\n";
    */
}
/*
void printASM(Module *M) {
//    InitializeNativeTarget();
//    InitializeNativeTargetAsmPrinter();

    auto TargetTriple = sys::getDefaultTargetTriple();
    M->setTargetTriple(TargetTriple);

    std::string Error;
    const Target *target = TargetRegistry::lookupTarget(TargetTriple, Error);
    auto cpu = sys::getHostCPUName();
    SubtargetFeatures Features;
    StringMap<bool> HostFeatures;
    if (sys::getHostCPUFeatures(HostFeatures))
        for (auto &F : HostFeatures)
            Features.AddFeature(F.first(), F.second);
    auto features = Features.getString();

    TargetOptions Options;
    std::unique_ptr<TargetMachine> TM{
            target->createTargetMachine(
                    TargetTriple, cpu, features, Options,
                    Reloc::PIC_, None, CodeGenOpt::None)
    };

    legacy::PassManager PM;
    M->setDataLayout(TM->createDataLayout());
    TM->addPassesToEmitFile(PM, (raw_pwrite_stream &) outs(), (raw_pwrite_stream *) (&outs()),
                            TargetMachine::CodeGenFileType::CGFT_AssemblyFile, true, nullptr);
    PM.run(*M);
}
*/

/* Executes the AST by running the main function */
GenericValue Codegen::runCode() {
	std::cout << "Running begining...\n";
	std::cout << 
	"========================================" << std::endl;
	ExecutionEngine *ee = EngineBuilder(std::unique_ptr<Module>(module)).create();
	std::vector<GenericValue> noargs;
	GenericValue v = ee->runFunction(mainFunction, noargs);
	std::cout << "========================================" << std::endl;
	std::cout << "Running end.\n";
//        printASM(module);
	return v;
}



