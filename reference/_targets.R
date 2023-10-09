library(targets)
suppressMessages(library(dplyr))
list(flowme::tar_duck_r(band_members_duck, {
    dplyr::copy_to(db, dplyr::band_members, name = "band_members_duck", 
        overwrite = TRUE, temporary = FALSE)
}), flowme::tar_duck_r(band_instruments_duck, {
    dplyr::copy_to(db, dplyr::band_instruments, name = "band_instruments_duck", 
        overwrite = TRUE, temporary = FALSE)
}), tar_target(join_to_targets, {
    arrange(collect(left_join(band_members_duck, band_instruments_duck)), 
        name)
}), flowme::tar_duck_r(join_to_duck, {
    foo <- arrange(collect(left_join(band_members_duck, band_instruments_duck)), 
        name)
    dplyr::copy_to(db, foo, name = "join_to_duck", overwrite = TRUE, 
        temporary = FALSE)
}), NULL)
