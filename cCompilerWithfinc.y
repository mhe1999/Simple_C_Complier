%{
#include <stdio.h>
#include <stdlib.h>

extern FILE *fp;
extern char * yytext;
FILE * f1;

char * name ;
char * num ;


%}

%token INT VOID UINT
%token WHILE 
%token IF ELSE SWITCH CASE BREAK DEFAULT
%token <charval> NUM 
%token <charval> ID
%token INCLUDE


%union {

	int intval;
	char*  	charval ;
	}



%right ASGN 
%left LOR
%left LAND
%left BOR
%left BXOR
%left BAND
%left EQ NE 
%left LE GE LT GT
%left '+' '-' 
%left '*' '/' '@'
%left '~'
%left O_PAR C_PAR


%nonassoc IFX IFX1
%nonassoc ELSE
  
%%

pgmstart 			: TYPE  ID {pushfuncname($2); } O_PAR ARGS {pushfunarguments($2);}

														 C_PAR STMTS {if(!strcmp ( $2 , "main"))

																{}
																else
																fprintf(f1 , "j $ra\n");}pgmstart  {findmain();}
                                |
				;

ARGS				: TYPE ID {setfuncargs(1);}|  TYPE ID ',' TYPE ID {setfuncargs(2);} | TYPE ID ',' TYPE ID ',' TYPE ID {setfuncargs(3);} | TYPE ID ',' TYPE ID ',' TYPE ID ',' TYPE ID 					{setfuncargs(4);} | {setfuncargs(0);}
					  
					  ;





STMTS 	: '{' STMT1 '}'|
				;
STMT1			: STMT  STMT1
				|
				;

STMT 			: STMT_DECLARE  // {printf("decccccc");} //all types of statements
				| STMT_ASSGN // {printf("assing");}
				| STMT_IF     //{printf("iffff");}
				| STMT_WHILE  //{printf("assing");}
				| STMT_FUNC    //{printf("funnnnn");}
				| ';'
				;


STMT_FUNC		: ID		O_PAR  ARG_FUNC C_PAR SEMICOLON {searchfuncname($1); searchfuncarguments($1); }      //'('arguments')'
			;

SEMICOLON		: ';' | ;

ARG_FUNC		:  A {setnumberofargs(1);}| A ',' A {setnumberofargs(2);}| A ',' A ',' A {setnumberofargs(3);} | A ',' A ',' A ',' A {setnumberofargs(4);} 
			|	{setnumberofargs(0);}
			;


A			: ID {fprintf(f1, "push $%s\n" , $1);} | NUM {fprintf(f1, "push $%s\n" , $1);}
			;	

EXP 			: EXP LT{push();} EXP {codegen_logical();}
				| EXP LE{push();} EXP {codegen_logical();}
				| EXP GT{push();} EXP {codegen_logical();} 
				| EXP GE{push();} EXP {codegen_logical();}
				| EXP NE{push();} EXP {codegen_logical();}
				| EXP EQ{push();} EXP {codegen_logical();}
				| EXP '+'{push();} EXP {codegen_algebric();}
				| EXP '-'{push();} EXP {codegen_algebric();}
				| EXP '*'{push();} EXP {codegen_algebric();}
				| EXP '/'{push();} EXP {codegen_algebric();}
                                | EXP {push();} LOR EXP {codegen_logical();}
				| EXP {push();} LAND EXP {codegen_logical();}
				| EXP {push();} BOR EXP {codegen_logical();}
				| EXP {push();} BXOR EXP {codegen_logical();}
				| EXP {push();} BAND EXP {codegen_logical();}
				| O_PAR EXP C_PAR
				| ID {check();push();}
				| NUM {push();}
				;


STMT_IF 			: IF O_PAR EXP C_PAR  {if_label1();} STMTS ELSESTMT 
				;
ELSESTMT		: ELSE  {if_label2();} STMTS {if_label3();}
				| {if_label3();}
				;



STMT_WHILE		:{while_start();} WHILE O_PAR EXP C_PAR {while_rep();} WHILEBODY  
				;

WHILEBODY		: STMTS {while_end();}
				| STMT {while_end();}
				;

STMT_DECLARE 	: TYPE {setType();}  ID {STMT_DECLARE();} IDS   //setting type for that line
				;


IDS 			: ';'
				| ','  ID {STMT_DECLARE();} IDS 
				;


STMT_ASSGN		: ID {push();} ASGN {push();} EXP {codegen_assign($1);} ';'
				;


TYPE			: INT
				| VOID	
				| UINT
				;

%%

#include <ctype.h>
#include <stdio.h>
#include"lex.yy.c"
int count=0;

char st[1000][10];
int top=0;
int i=0;
char temp[2]="t";
char funcname[10][50];
int funcnumber = 0;
int label[200];
int lnum=0;
int ltop=0;
int enterednumberofargs = 0;

int number_func_args = 0;

char type[10];
int flagofif; // > 1 // < 2 // >= 3 // <= 4 //

struct funcargcheck
{
char function_name[20];
int numberofargs ;

}funcargcheckid[10];


struct Table
{
	char id[20];
	char type[10];
}table[10000];
int tableCount=0;

int main(int argc, char *argv[])
{
	yyin = fopen(argv[1], "r");
	f1=fopen("output","w");
	
   if(!yyparse())
		printf("\nParsing complete\n");
	else
	{
		printf("\nParsing failed\n");
		exit(0);
	}
	
	fclose(yyin);
	fclose(f1);
	intermediateCode();
    return 0;
}

void setnumberofargs(int a)
{
enterednumberofargs = a;

}

void setfuncargs(int a)
{
	number_func_args = a;
}

void pushfunarguments(char * s)
{
	strcpy(funcargcheckid[funcnumber].function_name , s);
	funcargcheckid[funcnumber].numberofargs = number_func_args;
	//printf("%s:%d\n", funcargcheckid[funcnumber].function_name,funcargcheckid[funcnumber].numberofargs );
	//printf("funcnumber:%d\n" , funcnumber);
}


int findmain()
{


	for( int count =  0 ; count< funcnumber ; count++ )
	{
		if(!strcmp( "main" , funcname[count])	)
			return 0;
	
	}

	yyerror("function 'main' not exists.!");
	exit(0);


	
}

void pushfuncname(char * name)
{
	
	strcpy(funcname[funcnumber] , name );
	//printf("%s \n" , funcname[funcnumber]);
	fprintf(f1, "\n%s :\n\n", funcname[funcnumber]);
	funcnumber++;
	


}
int searchfuncarguments ( char * name)
{

	int c = 0;
	for(c = 0 ; c < funcnumber ; c++)
	{
		if(!strcmp(funcargcheckid[c].function_name , name))
		{
			if(funcargcheckid[c].numberofargs != enterednumberofargs)
			{
				yyerror("number of function arguments is not true!");
				exit(0);
			}
		}

	}

	
	



}

int searchfuncname (char * name)
{

	
	//printf("numberofargs: %d",enterednumberofargs);
	for( int counter =  0 ; counter< funcnumber ; counter++ )
	{	

		//printf("%d : %s\n" , counter ,funcname[counter]);

		//printf("%s\n",funcname[counter]);
		if(!strcmp( name , funcname[counter])	)
		{
			
			
			//printf("%s : %d \n", name, enterednumberofargs);
			fprintf(f1, "j %s\n" , name);
			return 0;
		}
		
	}
	 
			
				
			
			//printf("counter : %d\n\n" , counter);
			yyerror("Wrong call of function,Function not declared");
			exit(0);
		

	
	

}
         
yyerror(char *s) {
	printf("Syntex Error in line number : %d : %s %s\n", yylineno, s, yytext );
}
    
void push()
{
  	strcpy(st[++top],yytext);
}

void codegen_logical()
{
 	sprintf(temp,"$t%d",i);

	if( !strcmp ( "<" , st[top-1]))////////////////////////////// agar s[top] ha $ dashtan bayad ba if chek shavad 
		{fprintf(f1,"slt %s, $%s, $%s\n",temp,st[top-2],st[top]);
		flagofif = 2;}
	if( !strcmp ( ">" , st[top-1]))
		{fprintf(f1,"slt %s, %s, %s\n ",temp,st[top],st[top-2]);
		flagofif = 1;
		}
	if( !strcmp ( ">=" , st[top-1])){
		fprintf(f1,"slt %s, %s, %s\n ",temp,st[top],st[top-2]);
		fprintf(f1,"li $s0, 1\n");
		fprintf(f1, "xor %s, $s0, %s\n", temp , temp);
		flagofif = 3;
		}
	if( !strcmp ( "<=" , st[top-1])){
		fprintf(f1,"slt %s, %s, %s\n ",temp,st[top],st[top-2]);
		fprintf(f1,"li $s0, 1\n");
		fprintf(f1, "xor %s, $s0, %s\n", temp , temp);
		flagofif = 4;
		}
	
	


  	top-=2;
 	strcpy(st[top],temp);
 	i++;
}

void codegen_algebric()
{
 	sprintf(temp,"$t%d",i); // converts temp to reqd format
  	//fprintf(f1,"%s\t=\t%s\t%s\t%s\n",temp,st[top-2],st[top-1],st[top]);
	if(strcmp("+", st[top-1] )== 0)
	{
		fprintf(f1,"add %s, $%s, $%s \n",temp,st[top-2],st[top]);
	}
	if(strcmp("-", st[top-1] )== 0)
	{
		fprintf(f1,"sub %s, $%s, $%s \n",temp,st[top-2],st[top]);
	}
	if(strcmp("*", st[top-1] )== 0)
	{
		fprintf(f1,"mul %s, $%s, $%s \n",temp,st[top-2],st[top]);
	}
	if(strcmp("/", st[top-1] )== 0)
	{
		//printf("%s", st[top]);
		if( !strcmp(st[top] , "0"))
		{
			
			yyerror("division by zero ! ");
			exit(0);
				
		}
		fprintf(f1,"div %s, $%s, $%s \n",temp,st[top-2],st[top]);
	}
  	top-=2;
 	strcpy(st[top],temp);
 	i++;

	
}
void codegen_assign(char *codeasgn)
{
 	fprintf(f1,"li $%s , %s\n", /*st[top-2]*/codeasgn,st[top]);
 	top-=3;
}
 
void if_label1()
{
	//printf("%s" , st[top]);
 	lnum++;
	printf("");
 	//fprintf(f1,"\tif( not %s)",st[top]);
 	//fprintf(f1,"\tgoto $LABLE%d\n",lnum);
	if(flagofif == 1)
	{
	fprintf(f1,"beq $%s, $zero, $LABLE%d \n",st[top] ,lnum );
	}
	if(flagofif == 2)
	{
	fprintf(f1,"beq $%s, $zero, $LABLE%d \n",st[top] ,lnum );
	}
	if(flagofif == 3)
	{
	fprintf(f1,"beq $%s, $zero, $LABLE%d \n",st[top] ,lnum );
	}
	if(flagofif == 4)
	{
	fprintf(f1,"beq $%s, $zero, $LABLE%d \n",st[top] ,lnum );
	}
 	label[++ltop]=lnum;
}

void if_label2()
{	
	int x;
	lnum++;
	x=label[ltop--]; 
	fprintf(f1,"j $LABLE%d\n",lnum);
	fprintf(f1,"$LABLE%d:\n",x); 
	label[++ltop]=lnum;
}

void if_label3()
{
	int y;
	y=label[ltop--];
	fprintf(f1,"$LABLE%d:\n",y);
	top--;
}
void while_start()
{
	lnum++;
	label[++ltop]=lnum;
	fprintf(f1,"$LABLE%d:\n",lnum);
}
while_rep()
{
	lnum++;
	fprintf(f1,"beq %s, $zero, $LABLE%d\n",st[top] ,lnum );
 	label[++ltop]=lnum;
}
while_end()
{
	int x,y;
	y=label[ltop--];
	x=label[ltop--];
	fprintf(f1,"j $LABLE%d\n",x);
	fprintf(f1,"$LABLE%d: \n",y);
	top--;
}

/* for symbol table*/

check()
{
	char temp[20];
	strcpy(temp,yytext);
	int flag=0;
	for(i=0;i<tableCount;i++)
	{
		if(!strcmp(table[i].id,temp))
		{
			flag=1;
			break;
		}
	}
	if(!flag)
	{
		yyerror("Variable not declard");
		exit(0);
	}
}

setType()
{
	strcpy(type,yytext);
}


STMT_DECLARE()
{
	char temp[20];
	int i,flag;
	flag=0;
	strcpy(temp,yytext);
	for(i=0;i<tableCount;i++)
	{
		if(!strcmp(table[i].id,temp))
			{
			flag=1;
			break;
				}
	}
	if(flag)
	{
		yyerror("reSTMT_DECLARE of ");
		exit(0);
	}
	else
	{
		strcpy(table[tableCount].id,temp);
		strcpy(table[tableCount].type,type);
		tableCount++;
	}
}

intermediateCode()
{
	int Labels[100000];
	char buf[100];
	f1=fopen("output","r");
	int flag=0,lineno=1;
	memset(Labels,0,sizeof(Labels));
	while(fgets(buf,sizeof(buf),f1)!=NULL)
	{
		//printf("%s",buf);
		if(buf[0]=='$'&&buf[1]=='$'&&buf[2]=='L')
		{
			int k=atoi(&buf[3]);
			//printf("hi %d\n",k);
			Labels[k]=lineno;
		}
		else
		{
			lineno++;
		}
	}
	fclose(f1);
	f1=fopen("output","r");
	lineno=0;

	printf("\n\n\n*********************final Code***************************\n\n");
	while(fgets(buf,sizeof(buf),f1)!=NULL)
	{
		//printf("%s",buf);
		if(buf[0]=='$'&&buf[1]=='$'&&buf[2]=='L')
		{
			;
		}
		else
		{
			flag=0;
			lineno++;
			printf("%3d:\t",lineno);
			int len=strlen(buf),i,flag1=0;
			for(i=len-3;i>=0;i--)
			{
				if(buf[i]=='$'&&buf[i+1]=='$'&&buf[i+2]=='L')
				{
					flag1=1;
					break;
				}
			}
			if(flag1)
			{
				buf[i]=='\0';
				int k=atoi(&buf[i+3]),j;
				//printf("%s",buf);
				for(j=0;j<i;j++)
					printf("%c",buf[j]);
				printf(" %d\n",Labels[k]);
			}
			else printf("%s",buf);
		}
	}
	printf("%3d:\tend\n",++lineno);
	fclose(f1);
}
