module CUSOLVER

using CUDArt

import Base.one
import Base.zero

include("libcusolver_types.jl")

immutable CUSOLVERError <: Exception
    msg::AbstractString
    status::UInt32
    
    function CUSOLVERError(status)
        new(status,statusmessage(status))
    end
end

function statusmessage( status )
    if status == CUSOLVER_STATUS_SUCCESS
        return "cusolver success"
    elseif status == CUSOLVER_STATUS_NOT_INITIALIZED
        return "cusolver not initialized"
    elseif status == CUSOLVER_STATUS_ALLOC_FAILED
        return "cusolver allocation failed"
    elseif status == CUSOLVER_STATUS_INVALID_VALUE
        return "cusolver invalid value"
    elseif status == CUSOLVER_STATUS_ARCH_MISMATCH
        return "cusolver architecture mismatch"
    elseif status == CUSOLVER_STATUS_EXECUTION_FAILED
        return "cusolver execution failed"
    elseif status == CUSOLVER_STATUS_INTERNAL_ERROR
        return "cusolver internal error"
    elseif status == CUSOLVER_STATUS_MATRIX_TYPE_NOT_SUPPORTED
        return "cusolver matrix type not supported"
    end
end

function statuscheck( status )
    if status == CUSOLVER_STATUS_SUCCESS
        return nothing
    end
    warn("CUSOLVER error triggered from:")
    Base.show_backtrace(STDOUT, backtrace())
    println()
    throw(CUSOLVERError( status ))
end

const libcusolver = Libdl.find_library(["libcusolver"],["/usr/local/cuda"])
if isempty(libcusolver)
    error("CUSOLVER library not found in /usr/local/cuda!")
end

include("libcusolver.jl")

#setup handler for cusolver

cusolverSphandle = cusolverSpHandle_t[0]
cusolverSpCreate( cusolverSphandle )
cusolverDnhandle = cusolverDnHandle_t[0]
cusolverDnCreate( cusolverDnhandle )

function cusolverDestroy()
    cusolverSpDestroy(cusolverSphandle[1])
    cusolverDnDestroy(cusolverDnhandle[1])
end
#clean up handle at exit
atexit( ()->cusolverDestroy() )

include("sparse.jl")
include("dense.jl")

end
