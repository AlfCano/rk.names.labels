# Golden Rules of RKWard Plugin Development (Revised & Extended)
# Plugin: rk.names.labels (Data Tidy: Names and Labels)
# STATUS: FIXED (Added Syntactic, Unique, and Universal options to Tidy component)

local({
  # =========================================================================================
  # 1. Prerequisites & Package Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.10-3")

  package_about <- rk.XML.about(
    name = "rk.names.labels",
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "A plugin package to clean and create names and labels of variables of a data.frame or manipulate names in a list in the Rkward GUI.",
      version = "0.0.1",
      url = "https://github.com/AlfCano/rk.names.labels",
      license = "GPL (>= 3)"
    )
  )

  # =========================================================================================
  # 2. Reusable UI Elements
  # =========================================================================================

  var_select <- rk.XML.varselector(id.name = "vars")

  # =========================================================================================
  # Component 1: Tidy Names and Labels (Main Transformation)
  # =========================================================================================

  tn_target <- rk.XML.varslot("Select Data Frame or List", source = var_select, required = TRUE, classes = c("data.frame", "list"), id.name = "tn_obj")

  # 1. Name Repair Strategy (Comprehensive)
  tn_repair <- rk.XML.dropdown("Name Repair Strategy (Names Only)", options = list(
    "None" = list(val = "none", chk = TRUE),
    "Janitor (snake_case)" = list(val = "janitor"),
    "Make Syntactic (base::make.names)" = list(val = "syntactic"),
    "Make Unique (base::make.unique)" = list(val = "unique"),
    "Universal (vctrs/tibble)" = list(val = "universal")
  ), id.name = "tn_repair_method")

  # 2. Case Transformation
  tn_case <- rk.XML.radio("Case Transformation", options = list(
    "No Change" = list(val = "none", chk = TRUE),
    "Lowercase (tolower)" = list(val = "lower"),
    "Uppercase (toupper)" = list(val = "upper")
  ), id.name = "tn_case_method")

  # 3. Scope Selection
  tn_scope <- rk.XML.dropdown("Apply Transformations To", options = list(
      "Names Only" = list(val = "names", chk = TRUE),
      "Labels Only" = list(val = "labels"),
      "Both Names and Labels" = list(val = "both")
  ), id.name = "tn_scope")

  # 4. String Cleaning
  tn_stringr <- rk.XML.row(
    rk.XML.col(
      rk.XML.cbox("Trim Whitespace (str_trim)", value = "1", id.name = "tn_trim"),
      rk.XML.cbox("Squish Whitespace (str_squish)", value = "1", id.name = "tn_squish")
    )
  )

  tn_warning <- rk.XML.text("<b>Note:</b> 'Name Repair' strategies only affect Names. Case and Whitespace options apply based on the dropdown selection.")

  tn_actions <- rk.XML.frame(
    rk.XML.cbox("Copy variable names to labels (After processing)", value = "1", id.name = "tn_copy_to_label"),
    label = "Additional Actions"
  )

  # RULE 3: Hard-coded result name must match this initial value
  tn_save <- rk.XML.saveobj("Save result as", chk = TRUE, initial = "tidy_data", id.name = "tn_save_res")

  # Dialog with Tabs
  tn_dialog <- rk.XML.dialog(
    label = "Tidy Names and Labels",
    child = rk.XML.row(
      var_select,
      rk.XML.col(
        rk.XML.tabbook(tabs = list(
            "Input" = rk.XML.col(tn_target),
            "Transformations" = rk.XML.col(
                rk.XML.frame(tn_repair, label = "Structure & Repair"),
                rk.XML.frame(tn_case, label = "Case Conversion"),
                rk.XML.frame(
                    tn_scope,
                    tn_stringr,
                    label = "Scope and Cleanup"
                ),
                tn_warning
            ),
            "Output" = rk.XML.col(
                tn_actions,
                tn_save
            )
        ))
      )
    )
  )

  js_calc_tn <- '
    var obj = getValue("tn_obj");
    var repair_method = getValue("tn_repair_method");
    var case_method = getValue("tn_case_method");
    var scope = getValue("tn_scope");
    var do_trim = getValue("tn_trim");
    var do_squish = getValue("tn_squish");
    var copy_labels = getValue("tn_copy_to_label");

    var code = "res_obj <- " + obj + "\\n";
    code += "current_names <- names(res_obj)\\n";

    // 1. Name Repair (Strictly Names, applied first)
    if(repair_method == "janitor") {
        code += "res_obj <- janitor::clean_names(res_obj)\\n";
        code += "current_names <- names(res_obj)\\n";
    } else if (repair_method == "syntactic") {
        code += "current_names <- make.names(current_names, unique = TRUE)\\n";
    } else if (repair_method == "unique") {
        code += "current_names <- make.unique(current_names)\\n";
    } else if (repair_method == "universal") {
        code += "current_names <- vctrs::vec_as_names(current_names, repair = \\"universal\\", quiet = TRUE)\\n";
    }

    // 2. Process Names (If Scope includes Names)
    if(scope == "names" || scope == "both") {
        // A. Case
        if(case_method == "lower") {
            code += "current_names <- tolower(current_names)\\n";
        } else if (case_method == "upper") {
            code += "current_names <- toupper(current_names)\\n";
        }

        // B. Trim/Squish
        if(do_trim == "1") {
            code += "current_names <- stringr::str_trim(current_names)\\n";
        }
        if(do_squish == "1") {
            code += "current_names <- stringr::str_squish(current_names)\\n";
        }
    }

    // Apply name changes
    code += "names(res_obj) <- current_names\\n";

    // 3. Process Labels (If Scope includes Labels)
    if(scope == "labels" || scope == "both") {
         if(case_method != "none" || do_trim == "1" || do_squish == "1") {
             code += "# Cleaning Labels\\n";
             code += "for(n in names(res_obj)) {\\n";
             code += "  curr_lab <- rk.get.label(res_obj[[n]])\\n";
             code += "  if(!is.null(curr_lab) && !is.na(curr_lab)) {\\n";

             if(case_method == "lower") {
                code += "    curr_lab <- tolower(curr_lab)\\n";
             } else if (case_method == "upper") {
                code += "    curr_lab <- toupper(curr_lab)\\n";
             }

             if(do_trim == "1") {
                 code += "    curr_lab <- stringr::str_trim(curr_lab)\\n";
             }
             if(do_squish == "1") {
                 code += "    curr_lab <- stringr::str_squish(curr_lab)\\n";
             }

             code += "    rk.set.label(res_obj[[n]], curr_lab)\\n";
             code += "  }\\n";
             code += "}\\n";
         }
    }

    // 4. Copy Names to Labels (Overrides previous label cleaning if active)
    if(copy_labels == "1") {
       code += "# Copying names to variable labels\\n";
       code += "for(n in names(res_obj)) {\\n";
       code += "  if(!is.null(res_obj[[n]])) {\\n";
       code += "    rk.set.label(res_obj[[n]], n)\\n";
       code += "  }\\n";
       code += "}\\n";
    }

    // RULE 3: Unconditional assignment to hard-coded name "tidy_data"
    code += "tidy_data <- res_obj\\n";
    echo(code);
  '

  js_print_tn <- '
    echo("rk.header(\\"Tidy Names and Labels process completed.\\")\\n");
  '

  help_tn <- rk.rkh.doc(
    title = rk.rkh.title("Tidy Names and Labels"),
    summary = rk.rkh.summary("Provides tools to clean variable names and labels in data.frames or lists using standard R methods, 'janitor', and 'stringr'."),
    usage = rk.rkh.usage("Select a data.frame. Choose a name repair strategy (names only), then configure Case and Whitespace options which can apply to names, labels, or both."),
    settings = rk.rkh.settings(
        rk.rkh.setting(id = "tn_repair_method", text = "Method to standardise structure: Janitor (snake_case), Syntactic (valid R names), Unique, or Universal (robust)."),
        rk.rkh.setting(id = "tn_case_method", text = "Convert text to Lowercase or Uppercase."),
        rk.rkh.setting(id = "tn_scope", text = "Determines whether Case and Whitespace rules apply to Names, Labels, or Both."),
        rk.rkh.setting(id = "tn_trim", text = "Removes leading and trailing whitespace."),
        rk.rkh.setting(id = "tn_squish", text = "Reduces repeated internal whitespace to a single space."),
        rk.rkh.setting(id = "tn_copy_to_label", text = "If checked, overwrites the variable label with its new name.")
    )
  )

  # =========================================================================================
  # Component 2: Pattern Replacement
  # =========================================================================================

  rp_target <- rk.XML.varslot("Select Data Frame or List", source = var_select, required = TRUE, classes = c("data.frame", "list"), id.name = "rp_obj")
  rp_pattern <- rk.XML.input("Pattern (Regex)", id.name = "rp_pattern")
  rp_replace <- rk.XML.input("Replacement", id.name = "rp_replace")
  rp_scope <- rk.XML.radio("Scope", options = list("Names" = list(val = "names", chk = TRUE), "Labels" = list(val = "labels")), id.name = "rp_scope")

  # RULE 3: Hard-coded result name must match this initial value
  rp_save <- rk.XML.saveobj("Save result as", chk = TRUE, initial = "replaced_data", id.name = "rp_save_res")

  rp_dialog <- rk.XML.dialog(
    label = "Pattern Replacement",
    child = rk.XML.row(
      var_select,
      rk.XML.col(rp_target, rk.XML.frame(rp_pattern, rp_replace, label = "Substitution"), rp_scope, rp_save)
    )
  )

  js_calc_rp <- '
    var obj = getValue("rp_obj");
    var patt = getValue("rp_pattern");
    var repl = getValue("rp_replace");
    var scope = getValue("rp_scope");
    var code = "res_obj <- " + obj + "\\n";

    if(patt != "") {
        if(scope == "names") {
            code += "names(res_obj) <- stringr::str_replace_all(names(res_obj), pattern = \\"" + patt + "\\", replacement = \\"" + repl + "\\")\\n";
        } else {
            code += "for(col in names(res_obj)) {\\n";
            code += "  old_lab <- rk.get.label(res_obj[[col]])\\n";
            code += "  if(!is.null(old_lab) && !is.na(old_lab)) {\\n";
            code += "     new_lab <- stringr::str_replace_all(old_lab, pattern = \\"" + patt + "\\", replacement = \\"" + repl + "\\")\\n";
            code += "     rk.set.label(res_obj[[col]], new_lab)\\n";
            code += "  }\\n";
            code += "}\\n";
        }
    }
    // RULE 3: Unconditional assignment to hard-coded name "replaced_data"
    code += "replaced_data <- res_obj\\n";
    echo(code);
  '

  js_print_rp <- '
    echo("rk.header(\\"Pattern Replacement process completed.\\")\\n");
  '

  help_rp <- rk.rkh.doc(
    title = rk.rkh.title("Pattern Replacement"),
    summary = rk.rkh.summary("Performs regex pattern matching and replacement on names or labels."),
    usage = rk.rkh.usage("Select a data object, enter a regex pattern, and the replacement text."),
    settings = rk.rkh.settings(
        rk.rkh.setting(id = "rp_scope", text = "Choose whether to apply replacements to the object's column names or the variables' labels."),
        rk.rkh.setting(id = "rp_pattern", text = "The regular expression or string to search for."),
        rk.rkh.setting(id = "rp_replace", text = "The text to replace matches with.")
    )
  )

  component_rp <- rk.plugin.component("Pattern Replace", xml = list(dialog = rp_dialog), js = list(require = "stringr", calculate = js_calc_rp, printout = js_print_rp), rkh = list(help = help_rp), hierarchy = list("data", "Names and Labels"))

  # =========================================================================================
  # Component 3: Sequence Rename
  # =========================================================================================

  sr_target_df <- rk.XML.varslot("Select Data Frame", source = var_select, required=TRUE, classes="data.frame", id.name="sr_df")
  sr_cols <- rk.XML.varslot("Select Columns to Rename", source = var_select, required=TRUE, multi=TRUE, id.name="sr_cols")
  sr_mode <- rk.XML.radio("Mode", options = list("Sequence" = list(val = "seq", chk = TRUE), "Tibble Repair" = list(val = "tibble")), id.name = "sr_mode")

  sr_opts <- rk.XML.frame(
    rk.XML.input("Prefix", initial = "Var", id.name = "sr_prefix"),
    rk.XML.input("Suffix", id.name = "sr_suffix"),
    rk.XML.spinbox("Start Number", min = 1, initial = 1, id.name = "sr_start")
  )

  sr_tibble_opts <- rk.XML.dropdown("Repair Strategy", options = list("Universal" = list(val = "universal", chk = TRUE), "Unique" = list(val = "unique")), id.name = "sr_repair")

  # RULE 3: Hard-coded result name must match this initial value
  sr_save <- rk.XML.saveobj("Save Result", initial="renamed_df", id.name="sr_save")

  # Dialog with Tabs
  sr_dialog <- rk.XML.dialog(
      label = "Sequence Rename",
      child = rk.XML.row(
          var_select,
          rk.XML.col(
            rk.XML.tabbook(tabs = list(
                "Selection" = rk.XML.col(sr_target_df, sr_cols),
                "Configuration" = rk.XML.col(
                    sr_mode,
                    rk.XML.frame(sr_opts, label="Sequence Options"),
                    rk.XML.frame(sr_tibble_opts, label="Tibble Repair")
                ),
                "Output" = rk.XML.col(sr_save)
            ))
          )
      )
  )

  js_calc_sr <- '
    var df = getValue("sr_df");
    var cols = getValue("sr_cols").split("\\n");
    var mode = getValue("sr_mode");
    var code = "res_obj <- " + df + "\\n";

    if(mode == "seq") {
        var prefix = getValue("sr_prefix");
        var suffix = getValue("sr_suffix");
        var start_num = getValue("sr_start");
        var col_str = "";
        for (var i = 0; i < cols.length; i++) {
             var cl = cols[i].split("[[\\"").pop().replace(/\\"]]/g, "").replace(/\\"/g, "");
             if(i > 0) col_str += ", ";
             col_str += "\\\"" + cl + "\\\"";
        }
        code += "target_cols <- c(" + col_str + ")\\n";
        code += "sel_indices <- which(names(res_obj) %in% target_cols)\\n";
        code += "new_names <- paste0(\\\"" + prefix + "\\\", seq(from=" + start_num + ", length.out=length(sel_indices)), \\\"" + suffix + "\\\")\\n";
        code += "names(res_obj)[sel_indices] <- new_names\\n";
    } else {
        var strategy = getValue("sr_repair");
        code += "res_obj <- tibble::as_tibble(res_obj, .name_repair = \\\"" + strategy + "\\\")\\n";
    }
    // RULE 3: Unconditional assignment to hard-coded name "renamed_df"
    code += "renamed_df <- res_obj\\n";
    echo(code);
  '

  js_print_sr <- '
    echo("rk.header(\\"Sequence Rename / Repair process completed.\\")\\n");
  '

  help_sr <- rk.rkh.doc(
    title = rk.rkh.title("Sequence Rename"),
    summary = rk.rkh.summary("Renames specific columns or applies tibble repair."),
    usage = rk.rkh.usage("Select a dataframe and columns. Choose Sequence or Tibble Repair."),
    settings = rk.rkh.settings(
        rk.rkh.setting(id = "sr_mode", text = "Switch between sequential renaming of selected columns or full-table tibble name repair."),
        rk.rkh.setting(id = "sr_repair", text = "Tibble naming strategy (universal, unique, etc.)")
    )
  )

  component_sr <- rk.plugin.component("Sequence Rename", xml = list(dialog = sr_dialog), js = list(require = "tibble", calculate = js_calc_sr, printout = js_print_sr), rkh = list(help = help_sr), hierarchy = list("data", "Names and Labels"))

  # =========================================================================================
  # Component 4: Dictionary Lookup
  # =========================================================================================

  dl_target <- rk.XML.varslot("Target Data Frame", source = var_select, required = TRUE, classes = "data.frame", id.name = "dl_target")
  dl_dict <- rk.XML.varslot("Dictionary Data Frame", source = var_select, required = TRUE, classes = "data.frame", id.name = "dl_dict")
  dl_key <- rk.XML.input("Dictionary Key Column", id.name = "dl_key_col", required = TRUE)
  dl_val <- rk.XML.input("Dictionary Value Column", id.name = "dl_val_col", required = TRUE)

  # RULE 3: Hard-coded result name must match this initial value
  dl_save <- rk.XML.saveobj("Save Target as", chk=TRUE, initial="labeled_data", id.name="dl_save")

  dl_dialog <- rk.XML.dialog(
    label = "Dictionary Label Lookup",
    child = rk.XML.row(
      var_select,
      rk.XML.col(rk.XML.frame(dl_target, label="Data"), rk.XML.frame(dl_dict, label="Dictionary"), rk.XML.frame(dl_key, dl_val, label="Columns"), dl_save)
    )
  )

  js_calc_dl <- '
    var target = getValue("dl_target");
    var dict = getValue("dl_dict");
    var key = getValue("dl_key_col");
    var val = getValue("dl_val_col");

    var code = "res_obj <- " + target + "\\n";
    code += "dict_df <- " + dict + "\\n";
    code += "keys <- dict_df[[\\\"" + key + "\\\"]]\\n";
    code += "vals <- dict_df[[\\\"" + val + "\\\"]]\\n";

    code += "for(col_name in names(res_obj)) {\\n";
    code += "   match_idx <- match(col_name, keys)\\n";
    code += "   if(!is.na(match_idx)) {\\n";
    code += "       new_label <- as.character(vals[match_idx])\\n";
    code += "       rk.set.label(res_obj[[col_name]], new_label)\\n";
    code += "   }\\n";
    code += "}\\n";

    // RULE 3: Unconditional assignment to hard-coded name "labeled_data"
    code += "labeled_data <- res_obj\\n";
    echo(code);
  '

  js_print_dl <- '
    echo("rk.header(\\"Dictionary Labeling process completed.\\")\\n");
  '

  help_dl <- rk.rkh.doc(
      title = rk.rkh.title("Dictionary Label Lookup"),
      summary = rk.rkh.summary("Matches variable names against a dictionary."),
      usage = rk.rkh.usage("Select target and dictionary data frames. Enter column names for key and value."),
      settings = rk.rkh.settings(
        rk.rkh.setting(id = "dl_target", text = "The data frame whose variables will be labeled."),
        rk.rkh.setting(id = "dl_dict", text = "The data frame containing the key-value pairs."),
        rk.rkh.setting(id = "dl_key_col", text = "Name of the column in the dictionary that matches variable names."),
        rk.rkh.setting(id = "dl_val_col", text = "Name of the column in the dictionary containing the label text.")
      ),
      sections = list(
        rk.rkh.section("Requirements", "Dictionary columns must be valid.")
      )
  )

  component_dl <- rk.plugin.component("Dictionary Lookup", xml = list(dialog = dl_dialog), js = list(require = "lookup", calculate = js_calc_dl, printout = js_print_dl), rkh = list(help = help_dl), hierarchy = list("data", "Names and Labels"))

  # =========================================================================================
  # Main Skeleton Call
  # =========================================================================================

  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    xml = list(dialog = tn_dialog),
    js = list(require = c("janitor", "stringr", "vctrs"), calculate = js_calc_tn, printout = js_print_tn),
    rkh = list(help = help_tn),
    components = list(component_rp, component_sr, component_dl),
    pluginmap = list(name = "Tidy Names and Labels", hierarchy = list("data", "Names and Labels")),
    create = c("pmap", "xml", "js", "desc", "rkh"),
    load = TRUE,
    overwrite = TRUE,
    show = FALSE
  )

  cat("Plugin files generated successfully in '", normalizePath("."), "'. Run rk.updatePluginMessages('.') and devtools::install('.')", sep="")
})
