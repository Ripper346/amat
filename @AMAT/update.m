function update(mat, minCost, xc, yc, rc, newPixelsCovered)
    mat.covered(newPixelsCovered) = true;
    mat.price(newPixelsCovered) = minCost / mat.numNewPixelsCovered(yc, xc, rc);
    mat.axis(yc, xc, :) = mat.encoding(yc, xc, :, rc);
    mat.radius(yc, xc) = mat.scales(rc);
    mat.updateCosts(xc, yc, newPixelsCovered);
end
