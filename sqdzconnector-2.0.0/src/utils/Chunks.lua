Chunks = {}

function Chunks:tableChunks(tbl, size)
    local chunks = {}
    local chunk = {}
    for _, v in pairs(tbl) do
        chunk[#chunk + 1] = v
        if (#chunk >= size or next(tbl,_) == nil) then
            chunks[#chunks + 1] = chunk
            chunk = {}
        end
    end

    return chunks
end

function Chunks:getChunkOrNil(chunks, index)
    if (chunks[index] ~= nil) then
        return chunks[index]
    end
    return nil
end

function Chunks:reverseTable(tbl)
    local reversed = {}
    for k, v in pairs(tbl) do
        reversed[#tbl+1-k] = v
    end
    return reversed
end