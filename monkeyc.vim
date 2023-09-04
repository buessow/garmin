" Vim syntax file
" Language:	monkeyc

" quit when a syntax file was already loaded
" if exists("b:current_syntax")
"   finish
" endif

let s:cpo_save = &cpo
set cpo&vim

" A bunch of useful monkeyc keywords
syn keyword monkeycKeyword	class extends module function
syn keyword monkeycKeyword	using
syn keyword monkeycKeyword	if else for while try catch return break continue
syn keyword monkeycKeyword	hidden var const
syn match monkeycIdentifier	"[a-zA-Z][a-zA-Z0-9_]*"

syn keyword monkeycTodo 	contained	TODO

syn match  monkeycNumber		"\<\d\+\>"
syn region monkeycString       start="\"" skip="\\\"" end="\""

syn match   monkeycOperator	"[=<>+/*-]"
syn region  monkeycComment	start="/\*" end="\*/" contains=monkeycTodo
syn region  monkeycComment	start="//" end="$" contains=monkeycTodo

" Define the default highlighting.
" Only when an item doesn't have highlighting yet
hi def link monkeycNumber	Number
hi def link monkeycKeyword	Statement
hi def link monkeycString	String
hi def link monkeycComment	Comment
hi def link monkeycOperator	Special
hi def link monkeycIdentifier	Identifier
"hi def link monkeycTodo		Todo

let b:current_syntax = "monkeyc"

let &cpo = s:cpo_save
unlet s:cpo_save
" vim: ts=8
