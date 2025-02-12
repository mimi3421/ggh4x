base <- ggplot(iris, aes(Species, Sepal.Length)) +
  geom_point() +
  scale_y_sqrt()

# Grabbing scales
build <- ggplot_build(base)
scale_y <- build$layout$panel_params[[1]]$y # continuous
scale_x <- build$layout$panel_params[[1]]$x # discrete


# Construction ------------------------------------------------------------

test_that("constructor works", {
  guide <- guide_axis_manual(
    breaks = ~ .x, labels = ~ .x
  )
  expect_s3_class(guide, c("axis_manual", "axis_ggh4x", "guide", "axis"))

  expect_true(is.function(guide$breaks))
  expect_true(is.function(guide$labels))

})

# Correctness -------------------------------------------------------------

test_that("guide_axis_manual training is correct in continuous axes", {
  scale <- scale_y

  # Test default training, i.e. waivers
  guide <- guide_axis_manual()
  key <- guide_train(guide, scale)$key

  expect_equal(key$y, sqrt(c(5, 6, 7, 8)))
  expect_equal(key$.label, c("5", "6", "7", "8"))

  # Test manual breaks
  guide <- guide_axis_manual(breaks = c(5, 7))
  key <- guide_train(guide, scale)$key

  expect_equal(key$y, sqrt(c(5, 7)))
  expect_equal(key$.label, c("5", "7"))

  # Test manual labels
  guide <- guide_axis_manual(labels = LETTERS[1:4])
  key <- guide_train(guide, scale)$key

  expect_equal(key$y, sqrt(c(5, 6, 7, 8)))
  expect_equal(key$.label, LETTERS[1:4])

  # Test NULL breaks
  guide <- guide_axis_manual(breaks = NULL)
  key <- guide_train(guide, scale)$key

  expect_equal(nrow(key), 0)

  # Test NULL labels
  guide <- guide_axis_manual(labels = NULL)
  key <- guide_train(guide, scale)$key

  expect_equal(ncol(key), 2)

  # Test unit breaks
  guide <- guide_axis_manual(breaks = unit(c(0.45, 0.5, 0.55), "npc"),
                             labels = LETTERS[1:3])
  key <- guide_train(guide, scale)$key

  expect_s3_class(key$y, "unit")
  expect_equivalent(unclass(key$y), c(0.45, 0.5, 0.55))

  # Test function breaks and labels
  guide <- guide_axis_manual(breaks = mean,
                             labels = ~ .x^2)
  key <- guide_train(guide, scale)$key

  expect_equal(key$y, sqrt(6.1))
  expect_equal(key$.label, 6.1^2)

})

test_that("guide_axis_manual training is correct in continuous axes", {
  scale <- scale_x

  # Test basic functionality
  guide <- guide_axis_manual()
  key <- guide_train(guide, scale)$key

  expect_equal(key$x, structure(c(1, 2, 3),
                                class = c("mapped_discrete", "numeric")))
  expect_equal(key$.label, c("setosa", "versicolor", "virginica"))

  # Test manual breaks and labels
  guide <- guide_axis_manual(breaks = seq(0.5, 3.5, by = 1),
                             labels = LETTERS[1:4])
  key <- guide_train(guide, scale)$key

  expect_equal(key$x, structure(c(0.5, 1.5, 2.5, 3.5),
                                class = c("mapped_discrete", "numeric")))
  expect_equal(key$.label, LETTERS[1:4])

  # Test function breaks and labels
  guide <- guide_axis_manual(breaks = rev, labels = toupper)
  key <- guide_train(guide, scale)$key

  expect_equal(key$x, structure(c(3, 2, 1),
                                class = c("mapped_discrete", "numeric")))
  expect_equal(key$.label, c("VIRGINICA", "VERSICOLOR", "SETOSA"))

  # Test unit breaks
  guide <- guide_axis_manual(breaks = unit(0.5, "npc"), labels = "A")
  key <- guide_train(guide, scale)$key
  xx <<- key

  expect_equivalent(unclass(key$x), c(0.5))
  expect_s3_class(key$x, "unit")
})



test_that("guide_axis_manual can be placed at every position", {
  g <- guides(
    x = guide_axis_manual(label_colour = c("green", "red", "blue")),
    x.sec = guide_axis_manual(breaks = unit(c(0.1, 0.2), "npc"),
                              labels = c("A", "B")),
    y = guide_axis_manual(label_face = "bold"),
    y.sec = guide_axis_manual(breaks = c(5, 7),
                              labels = ~ .x ^ 2)
  )

  gt <- ggplotGrob(base + g)
  expect_s3_class(gt, "gtable")

  left <- gt$grobs[gt$layout$name == "axis-l"][[1]]$children[[2]]
  expect_equal(left$grobs[[1]]$children[[1]]$gp$fontface, rep("bold", 4))

  right <- gt$grobs[gt$layout$name == "axis-r"][[1]]$children[[2]]
  expect_equal(right$grobs[[2]]$children[[1]]$y,
               left$grobs[[1]]$children[[1]]$y[c(1,3)])

  top <- gt$grobs[gt$layout$name == "axis-t"][[1]]$children[[2]]
  expect_equivalent(unclass(top$grobs[[1]]$children[[1]]$x), c(0.1, 0.2))

  bottom <- gt$grobs[gt$layout$name == "axis-b"][[1]]$children[[2]]
  expect_equivalent(bottom$grobs[[2]]$children[[1]]$gp$col,
                    c("green", "red", "blue"))
})

# Warnings and errors -----------------------------------------------------

test_that("warnings and errors work", {
  guide <- guide_axis_manual(breaks = unit(0.5, "cm"))
  expr <- substitute(guide_train(guide, scale_y))

  expect_warning(expect_error(eval(expr), "not meaningful for units"),
                 "Setting units for breaks might not work")

  guide <- guide_axis_manual()
  guide$available_aes <- "z"
  test <- substitute(guide_train(guide, scale_x))
  expect_warning(eval(test), "needs appropriate scales")

})
