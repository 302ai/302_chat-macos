//
//  LlamaTypeAlias.swift
//  Chat302AI-Mac
//


import Foundation
import llama

typealias CPPBatch = llama_batch
typealias CPPModel = OpaquePointer
typealias CPPContext = OpaquePointer
typealias CPPToken = llama_token
typealias CPPPosition = llama_pos
typealias CPPSeqID = llama_seq_id
typealias CPPContextParameters = llama_context_params
