#using MPILib

path="$(homedir())/Desktop/test/"

tikzName="rawtikz.tikz"
texName = "sAtikz.tex"

tikz ="""\\tikzset{every node/.style={inner sep=0,outer sep=0}}
\\ifdef{\\imageSize}{}{\\def\\imageSize{2cm}}
\\def\\dir{Images/}
\\def\\preFix{fusedFrame}
\\def\\pheight{\\imageSize}
\\def\\pwidth{\\imageSize}
\\def\\MRIResX{128}
\\def\\MRIResY{128}
\\def\\MRIResZ{128}
\\def\\SFSizeX{120}
\\def\\SFSizeY{120}
\\def\\SFSizeZ{64}
\\def\\SFCenterX{0}
\\def\\SFCenterY{0}
\\def\\SFCenterZ{0}
\\def\\ImageFrame{30}
\\def\\MRISliceX{107}
\\def\\MRISliceY{74}
\\def\\MRISliceZ{73}
\\ifdef{\\NodeName}{}{\\def\\NodeName{}}
\\ifdef{\\PosArguments}{\\def\\AxisArgs{\\PosArguments}}{\\def\\AxisArgs{}}
\\ifdef{\\ImageLabel}{\\def\\Label{\\ImageLabel}}{\\def\\Label{}}
\\ifdef{\\arrowColor}{\\def\\AColor{\\arrowcolor}}{\\def\\AColor{white}}
\\ifdef{\\Position}{\\def\\Pos{\\Position}}{\\def\\Pos{0,0}}
%%%%%%
	\\InVivoImages{\\NodeName}{\\Pos}{\\MRISliceX}{\\MRISliceY}{\\MRISliceZ}{\\ImageFrame}{\\AxisArgs}{\\Label}{\\AColor}
%%%%%
\\undef{\\PosArguments}
\\undef{\\ImageLabel}
\\undef{\\arrowColor}
\\undef{\\Position}
\\undef{\\NodeName}"""

open(joinpath(path,tikzName), "w") do f
   write(f,tikz)
end

tex="""\\documentclass{standalone}
\\usepackage{pgfplots}
\\usepackage{textcomp}
\\usepackage{etoolbox}
\\usetikzlibrary{calc,arrows.meta}
	\\input{InVivoFusedImages.tex}
\\begin{document}
	\\begin{tikzpicture}[]
		\\input{$(tikzName)}
	\\end{tikzpicture}
\\end{document}
% covert command
%convert -density 300 JuliaOut.pdf JuliaOut.png
%/mnt/results/20161124_WT2006/recoNew.jl
% Messung:
% 20161124_WT2006_1/Bolus3(E4)   Reco 4
% MRI fl3d_vibe_lowres.nii"""

open(joinpath(path,texName), "w") do f
   write(f,tex)
end

sourcePath="$(homedir())/.julia/v0.5/MPILibScripts/src/InVivoFusedImages.tex"
cp(sourcePath,joinpath(path,"InVivoFusedImages.tex"),remove_destination=true)

cd(path)
run(`pdflatex $(joinpath(path,texName))`)
fileName,ext=splitext(joinpath(path,texName))
run(`convert -density 300 $(basename(fileName)).pdf $(basename(fileName)).png`)
