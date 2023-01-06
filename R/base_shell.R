base_shell <- function (cmd, shell, flag = "/c", intern = FALSE, wait = TRUE,
    translate = FALSE, mustWork = FALSE, ...)
{
    if (missing(shell)) {
        shell <- Sys.getenv("R_SHELL")
        if (!nzchar(shell))
            shell <- Sys.getenv("COMSPEC")
    }
    if (missing(flag) && any(!is.na(pmatch(c("bash", "tcsh",
        "sh"), basename(shell)))))
        flag <- "-c"
    cmd0 <- cmd
    if (translate)
        cmd <- chartr("/", "\\", cmd)
    if (!is.null(shell))
        cmd <- paste(shell, flag, cmd)
    res <- system(cmd, intern = intern, wait = wait | intern,
        show.output.on.console = wait, ...)
    if (!intern && res && !is.na(mustWork))
        if (mustWork)
            if (res == -1L)
                stop(gettextf("'%s' could not be run",
                  cmd0), domain = NA)
            else stop(gettextf("'%s' execution failed with error code %d",
                cmd0, res), domain = NA)
        else if (res == -1L)
            warning(gettextf("'%s' could not be run", cmd0),
                domain = NA)
        else warning(gettextf("'%s' execution failed with error code %d",
            cmd0, res), domain = NA)
    if (intern)
        res
    else invisible(res)
}
