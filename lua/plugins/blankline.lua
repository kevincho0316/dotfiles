-- this will make a guide line for opening and closing
return{
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {},
    content = function ()
        require("ibl").setup()
    end
}
