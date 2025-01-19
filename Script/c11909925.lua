--Snake-Eyes Execute Dragon
local s,id=GetID()
function s.initial_effect(c)
    --Synchro Summon
    Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1,Synchro.NonTuner(nil),1,99)
    c:EnableReviveLimit()

    --Main Phase Effect (Quick Effect): Place as Continuous Spell, then lock next turn
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOFIELD)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.ctcon)
    e1:SetTarget(s.cttg)
    e1:SetOperation(s.ctop)
    c:RegisterEffect(e1)

    -- Reset the effect lock at the start of the next turn
    local e1b=Effect.CreateEffect(c)
    e1b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1b:SetCode(EVENT_PHASE_START+PHASE_DRAW)
    e1b:SetCountLimit(1,{id,2}) -- Prevents multiple resets
    e1b:SetOperation(s.resetflag)
    Duel.RegisterEffect(e1b,0)
    Duel.RegisterEffect(e1b,1)

    --Battle Phase Effect (Quick Effect): Destroy 1 Monster & 1 Continuous Spell
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
end

-- Condition to restrict "Place as Continuous Spell" to Main Phase and prevent activation in the next turn
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase() and e:GetHandler():GetFlagEffect(id)==0
end

-- Select target to place as Continuous Spell
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE+LOCATION_GRAVE) and chkc:IsFaceup() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,1,nil)
end

-- Place target as Continuous Spell & lock effect for next turn
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoGrave(tc,REASON_RULE)
        local zone=Duel.GetLocationCount(tc:GetControler(),LOCATION_SZONE)
        if zone>0 then
            Duel.MoveToField(tc,tp,tc:GetControler(),LOCATION_SZONE,POS_FACEUP,true)
        end
    end
    e:GetHandler():RegisterFlagEffect(id,RESET_PHASE+PHASE_END+RESET_OPPO_TURN,0,1) -- Locks effect until next turn ends
end

-- Reset the lock at the start of the next turn
function s.resetflag(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
    for tc in aux.Next(g) do
        tc:ResetFlagEffect(id)
    end
end

-- Select & Destroy 1 Monster & 1 Continuous Spell
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,TYPE_MONSTER) 
        and Duel.IsExistingTarget(Card.IsType,tp,LOCATION_SZONE,LOCATION_SZONE,1,nil,TYPE_CONTINUOUS) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g1=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,TYPE_MONSTER)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g2=Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_SZONE,LOCATION_SZONE,1,1,nil,TYPE_CONTINUOUS)
    g1:Merge(g2)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,#g1,0,0)
end

-- Destroy selected Monster & Continuous Spell
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end
