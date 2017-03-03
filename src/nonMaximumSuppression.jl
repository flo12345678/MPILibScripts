@doc ""->
function nonMaximumSuppression(gradXYZ, gradX, gradY, gradZ)

  norm_gradX=gradX./gradXYZ
  norm_gradY=gradY./gradXYZ
  norm_gradZ=gradZ./gradXYZ
  indX=find(x->isequal(x,NaN),norm_gradX)
  indY=find(x->isequal(x,NaN),norm_gradY)
  indZ=find(x->isequal(x,NaN),norm_gradZ)
  norm_gradX[indX]=0.0
  norm_gradY[indY]=0.0
  norm_gradZ[indZ]=0.0

  xSize,ySize,zSize=size(gradXYZ)
  direction=[-1; 1]
  for k=1:xSize
    for l=1:ySize
      for m=1:zSize
        for n=1:length(direction)
          kNeighbor= round(Int64, k + direction[n] * norm_gradX[k,l,m], RoundNearestTiesAway)
          lNeighbor= round(Int64, l + direction[n] * norm_gradY[k,l,m], RoundNearestTiesAway)
          mNeighbor= round(Int64, m + direction[n] * norm_gradZ[k,l,m], RoundNearestTiesAway)

        if kNeighbor >=1 && kNeighbor <= xSize && lNeighbor >=1 && lNeighbor <= ySize && mNeighbor >=1 && mNeighbor <= zSize
          if gradXYZ[k,l,m] < gradXYZ[kNeighbor,lNeighbor,mNeighbor]
              gradXYZ[k,l,m] = 0.0
          end
        end

      end
      end
    end
  end

 return gradXYZ
end

@doc ""->
function nonMaximumSuppressionAngle(gradXYZ, gradX, gradY, gradZ)
  theta = acos(gradZ./gradXYZ) # incliniation
  phi = atan2(gradY, gradX) # azimuth


  xSize,ySize,zSize=size(gradXYZ)
  for k=1:xSize
    for l=1:ySize
      for m=1:zSize
        tempTheta=theta[k,l,m]
        tempPhi=phi[k,l,m]

      end
    end
  end



end
