TaxaOut <- function(name, lBound = 0.0, hBound = 1.0E100, writeTrees = T) {

options (warn = -1)

  inFileName <- paste0(name, ".xml")
  inFile <- readLines(inFileName)
  ver2 <- grep(pattern = "version=\"2.0\"", x = inFile, value = F)  
  ver1 <- grep(pattern = "version=\"1.0\"", x = inFile, value = F)  
  ver <- length(ver1) + length(ver2)

if (ver == 1) {
  endTaxaLine <- grep(pattern = "</taxa>", x = inFile, value = F)
  taxaLine <- grep(pattern = "<taxon id=", x = inFile, value = T)
  taxaLinePosition <- grep(pattern = "<taxon id=", x = inFile, value = F)
  taxaLine <- unlist(strsplit(taxaLine, "\""))
  taxa <- taxaLine[c (F, T, F)]
  numberTaxa <- length(taxa)
  
  if (length(taxa) == 0) {stop(
    "No date info found, check Beast input file")}  

  # Loop
  for (i in 1 : numberTaxa) { 
    newFile <- inFile
    taxon <- taxa[i]
    add1 <- grep(pattern = "</taxa>", x = newFile, value = F)
    newFile [add1] <- paste0("\t</taxa>\n\n","\t<taxa id=\"leave_out\">\n",
                             "\t\t<taxon idref=\"",taxon,"\"/>\n\t</taxa>")
    add2 <- grep(pattern = "</treeModel>", x = newFile, value = F)
    newFile [add2] <- paste0(
      "\n\t<!-- START Tip date sampling\t\t\t\t\t\t\t\t\t\t\t-->
      \n\t\t<leafHeight taxon=\"",taxon,"\">\n\t\t\t<parameter id=\"age(",
      taxon,")\"/>\n\t\t</leafHeight>
      \n\t<!-- END Tip date sampling\t\t\t\t\t\t\t\t\t\t\t\t-->
      \n\t</treeModel>","\n\n\t<!-- Taxon Sets\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t-->
      \t<tmrcaStatistic id=\"tmrca(leave_out)\" includeStem=\"false\">
      \t\t<mrca>\n\t\t\t<taxa idref=\"leave_out\"/>\n\t\t</mrca>
      \t\t<treeModel idref=\"treeModel\"/>\n\t</tmrcaStatistic>")
    add34 <- grep(pattern = "</operators>", x = newFile, value = F)
    newFile [add34] <- paste0(
      "\t\t<scaleOperator scaleFactor=\"0.9\" weight=\"1\">
      \t\t\t<parameter idref=\"age(",taxon,")\"/>\n\t\t</scaleOperator>
      \t</operators>")
    add5 <- grep(pattern = "<prior id=\"prior\">", x = newFile, value = F)
    newFile [add5] <- paste0(
      "\t\t\t<prior id=\"prior\">
      \t\t\t<uniformPrior lower=\"", lBound, "\" upper=\"",hBound,"\">
      \t\t\t\t\t<parameter idref=\"age(",taxon,
      ")\"/>\n\t\t\t\t</uniformPrior>")
    add6 <- grep(pattern = "<log id=\"fileLog\"", x = newFile, value = F)
    keep6 <- newFile[add6 + 1]
    newFile [add6 + 1] <- paste0(
      "\n\t\t\t<parameter idref=\"age(",taxon,")\"/>\n",keep6)

    log = paste0("\\.log")
    matchLog <- grep(pattern = log, x = newFile, value = T)
    matchLogPosition <- grep(pattern = log, x = newFile, value = F)
    logRep <- paste0("\\.Taxon", i, log)
    if (length(matchLogPosition) != 0) {
      newFile [matchLogPosition] <- gsub(log, logRep, matchLog)}
    
    trees = paste0("\\.trees")
    matchTrees <- grep(pattern = trees, x = newFile, value = T)
    matchTreesPosition <- grep(pattern = trees, x = newFile, value = F)
    treesRep <- paste0("\\.Taxon", i, trees)
    if (length(matchTreesPosition) != 0) {
      newFile [matchTreesPosition] <- gsub(trees, treesRep, matchTrees)}    

    csv = paste0("\\.csv")
    matchCsv <- grep(pattern = csv, x = newFile, value = T)
    matchCsvPosition <- grep(pattern = csv, x = newFile, value = F) 
    csvRep <- paste0("\\.Taxon", i, csv)
    if (length(matchCsvPosition) != 0) {
      newFile [matchCsvPosition] <- gsub(csv, csvRep, matchCsv)}

    ops = paste0("\\.ops")
    matchOps <- grep(pattern = ops, x = newFile, value = T)
    matchOpsPosition <- grep(pattern = ops, x = newFile, value = F) 
    opsRep <- paste0("\\.Taxon", i, ops)
    if (length(matchOpsPosition) != 0) {
      newFile [matchOpsPosition] <- gsub(ops, opsRep, matchOps)}
    
    if (writeTrees == F) {
    logA <- grep(pattern = "<logTree id=", x = newFile, value = T)
    logAn <- grep(pattern = "<logTree id=", x = newFile, value = F)
    newFile [logAn] <- paste0("\t\t<!-- \n", logA)
    logB <- grep(pattern = "</logTree>", x = newFile, value = T)
    logBn <- grep(pattern = "</logTree>", x = newFile, value = F)
    newFile [logBn] <- paste0(logB, "\n", " \t\t -->")
    }
    
    out <- paste0(name, ".Taxon", i, ".xml")
    cat (newFile, file = out, sep = "\n")
    cat ("Taxon", i, "processed \n")
  }
}

if (ver == 2) {
  numberTaxa <- length(grep("taxon=", inFile))
  line <- grep(pattern = "traitname=\"date|traitname=\'date", x = inFile)
  line <- line + 1
  if (length(line) == 0) {stop(
    "No date info found, check BEAST input file")} 
  datePositions = c()
  repeat {
    if (length(grep("value=", inFile[line])) > 0) line <- line + 1
    if (length(grep("alignment", inFile[line])) > 0) break
    if (length(grep("=", inFile[line])) > 0) {
      datePositions <- c(datePositions, line)}
    line <- line + 1
  }
  numberDates <- length(datePositions)
  dateLines <- inFile[datePositions]
  dateLines <- trimws(dateLines)
  date <- unlist(strsplit(dateLines, "="))
  dateHap <- date[c(T, F)]
  dateHap <- dateHap[1: numberDates]
  dateValues <- date[c(F, T)]
  lastLine <- length(grep("<taxa", dateValues))
  
  if (lastLine == 1){
    lastDate <- tail(dateValues, 2)
    lastDate <- unlist(strsplit(lastDate, " "))
    lastDate <- head(lastDate, 1)
    dateValues <- head(dateValues, numberTaxa-1)
    dateValues <- c(dateValues, lastDate)
  }
  
  dateValues <- gsub(",$", "", dateValues)
  
  lineTrees <- grep(pattern ="@Tree.t:", x = inFile)
  lineTree <- tail(lineTrees, 1) 
  treeLine <- inFile[lineTree]
  treePart <- tail(unlist(strsplit(treeLine, "@Tree.t:")), 1)
  treeName <- head(unlist(strsplit(treePart, "\"")), 1)
  for (i in 1 : numberTaxa) {
    newFile <- inFile
    addLine1 <- grep(pattern = "</prior>", x = newFile)
    add1 <- tail(addLine1, n = 1)
    temp1 <- newFile[add1]
    newFile [add1] <- paste0(temp1, "\n",
                        "\t\t\t<distribution id=\"LOOCV.prior\"",
                        " spec=\"beast.math.distributions.MRCAPrior\" ",
                        "tipsonly=\"true\" tree=\"@Tree.t:",
                        treeName, "\">\n",
                        "\t\t\t\t<taxonset id=\"LOOCV\" spec=\"TaxonSet\">\n",
                        "\t\t\t\t<taxon id=\"", dateHap[i],
                        "\" spec=\"Taxon\"/>\n",
                        "\t\t\t\t</taxonset>\n",
                        "\t\t\t\t<Uniform id=\"Uniform.S\" lower=\"",lBound,
                        "\" name=\"distr\" upper=\"",hBound,"\"/>",
                        "\t\t\t\t</distribution>")
    addLine2 <- grep(pattern = "</operator>", x = newFile)
    add2 <- tail(addLine2, n = 1)
    temp2 <- newFile[add2]
    newFile [add2] <- paste0(temp2,"\n\n",
                        "\t<operator id=\"TipDatesRandomWalker.01\"",
                        "  windowSize=\"1\" spec=\"TipDatesRandomWalker\"",
                        "\ taxonset=\"@LOOCV\" tree=\"@Tree.t:",
                        treeName,"\" weight=\"1.0\"/>")
    add6 <- grep(pattern = "<logger id=\"tracelog\" fileName=", x = newFile,
                 value = F)
    keep6 <- newFile[add6]
    newFile [add6] <- paste0(keep6,"\n\t\t<log idref=\"LOOCV.prior\"/>")

    log = paste0("\\.log")
    matchLog <- grep(pattern = log, x = newFile, value = T)
    matchLogPosition <- grep(pattern = log, x = newFile, value = F)
    logRep <- paste0("\\.Taxon", i, log)
    if (length(matchLogPosition) != 0) {
      newFile [matchLogPosition] <- gsub(log, logRep, matchLog)}
    
    trees = paste0("\\.trees")
    matchTrees <- grep(pattern = trees, x = newFile, value = T)
    matchTreesPosition <- grep(pattern = trees, x = newFile, value = F)
    treesRep <- paste0("\\.Taxon", i, trees)
    if (length(matchTreesPosition) != 0) {
      newFile [matchTreesPosition] <- gsub(trees, treesRep, matchTrees)}

    if (writeTrees == F) {
      logA <- grep(pattern = "\\.trees", x = newFile, value = T)
      logAn <- grep(pattern = "\\.trees", x = newFile, value = F)
      newFile [logAn] <- paste0("\t<!-- \n ", logA)
      ctr <- 0
      repeat {
        ctr <- ctr + 1
        ctr2 <- 0
        ctr2 <- logAn + ctr
        temp <- grep(pattern = "</logger>", newFile[ctr2], value = F)
        temp <- length(temp)
        if (temp != 0) break
        if (ctr == 100) stop("Error, check files, no tree block found")
      }
      newFile [ctr2] <- paste0("\t</logger>", "\n", "\t-->")
    }
    
    out <- paste0(name, ".Taxon", i, ".xml")
    cat (newFile, file = out, sep = "\n")
    cat ("Taxon", i, "processed \n")
  }
}

if (ver != 1 & ver != 2) {stop("Error, check BEAST input files")}

}